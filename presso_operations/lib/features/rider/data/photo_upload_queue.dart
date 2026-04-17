// Offline-first photo upload queue.
//
// The rider captures pickup photos in areas with patchy or no signal. We
// can't make them stand still waiting for a flaky upload — they need to keep
// moving. This queue:
//
//   1. Copies each captured photo into the app's documents directory so the
//      file survives iOS tmp wipes and app restarts.
//   2. Persists a JSON index of pending uploads to SharedPreferences.
//   3. Runs a background processor that retries pending uploads whenever the
//      device is online (driven by connectivity_plus + a 10s heartbeat).
//
// The PhotoCaptureScreen enqueues photos and lets the rider proceed even
// before all uploads complete. Per-photo status (pending/uploading/uploaded/
// failed) is exposed via the StateNotifier so the UI can render upload chips.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:presso_operations/features/rider/data/rider_repository.dart';

enum QueuedPhotoStatus { pending, uploading, uploaded, failed }

class QueuedPhoto {
  final String id;
  final String assignmentId;
  final String localPath;
  final QueuedPhotoStatus status;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;

  const QueuedPhoto({
    required this.id,
    required this.assignmentId,
    required this.localPath,
    required this.status,
    required this.attempts,
    required this.createdAt,
    this.lastError,
  });

  QueuedPhoto copyWith({
    QueuedPhotoStatus? status,
    int? attempts,
    String? lastError,
    bool clearError = false,
  }) =>
      QueuedPhoto(
        id: id,
        assignmentId: assignmentId,
        localPath: localPath,
        status: status ?? this.status,
        attempts: attempts ?? this.attempts,
        lastError: clearError ? null : (lastError ?? this.lastError),
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'assignmentId': assignmentId,
        'localPath': localPath,
        'status': status.name,
        'attempts': attempts,
        'lastError': lastError,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QueuedPhoto.fromJson(Map<String, dynamic> json) => QueuedPhoto(
        id: json['id'] as String,
        assignmentId: json['assignmentId'] as String,
        localPath: json['localPath'] as String,
        status: QueuedPhotoStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => QueuedPhotoStatus.pending,
        ),
        attempts: json['attempts'] as int? ?? 0,
        lastError: json['lastError'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class PhotoUploadQueueNotifier extends StateNotifier<List<QueuedPhoto>> {
  final RiderRepository _repo;
  static const _prefsKey = 'photo_upload_queue_v1';
  static const _maxAttempts = 5;
  Timer? _heartbeat;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _processing = false;
  bool _loaded = false;

  PhotoUploadQueueNotifier(this._repo) : super(const []) {
    _init();
  }

  Future<void> _init() async {
    await _load();
    _loaded = true;
    // Reset any entries stuck in "uploading" (from a previous session that
    // died mid-upload) so the processor picks them up again.
    state = [
      for (final p in state)
        if (p.status == QueuedPhotoStatus.uploading)
          p.copyWith(status: QueuedPhotoStatus.pending)
        else
          p
    ];
    await _save();

    _heartbeat =
        Timer.periodic(const Duration(seconds: 10), (_) => processPending());
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        processPending();
      }
    });
    // Kick once on boot.
    processPending();
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      state = list
          .map((e) => QueuedPhoto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      state = const [];
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  /// Copy the captured file into the app documents dir (so it survives iOS
  /// tmp wipes), enqueue it, and immediately kick the processor.
  Future<QueuedPhoto> enqueue(String assignmentId, File sourceFile) async {
    while (!_loaded) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    final dir = await getApplicationDocumentsDirectory();
    final queueDir = Directory('${dir.path}/photo_queue');
    if (!await queueDir.exists()) {
      await queueDir.create(recursive: true);
    }
    final id = '${DateTime.now().microsecondsSinceEpoch}_'
        '${sourceFile.path.hashCode.toUnsigned(32)}';
    final ext = sourceFile.path.contains('.')
        ? sourceFile.path.split('.').last
        : 'jpg';
    final targetPath = '${queueDir.path}/$id.$ext';
    await sourceFile.copy(targetPath);

    final entry = QueuedPhoto(
      id: id,
      assignmentId: assignmentId,
      localPath: targetPath,
      status: QueuedPhotoStatus.pending,
      attempts: 0,
      createdAt: DateTime.now(),
    );
    state = [...state, entry];
    await _save();
    // Fire and forget.
    processPending();
    return entry;
  }

  /// Retry a single failed/pending entry on user request.
  Future<void> retry(String id) async {
    state = [
      for (final p in state)
        if (p.id == id)
          p.copyWith(
            status: QueuedPhotoStatus.pending,
            attempts: 0,
            clearError: true,
          )
        else
          p
    ];
    await _save();
    processPending();
  }

  /// Remove uploaded entries for an assignment (optional cleanup hook).
  Future<void> purgeUploadedFor(String assignmentId) async {
    final toRemove = state
        .where((p) =>
            p.assignmentId == assignmentId &&
            p.status == QueuedPhotoStatus.uploaded)
        .toList();
    for (final p in toRemove) {
      try {
        final f = File(p.localPath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    state = state
        .where((p) => !(p.assignmentId == assignmentId &&
            p.status == QueuedPhotoStatus.uploaded))
        .toList();
    await _save();
  }

  /// Processor — picks one pending photo at a time and uploads it. Serial on
  /// purpose so we don't hammer a flaky connection with N parallel requests.
  Future<void> processPending() async {
    if (_processing) return;
    _processing = true;
    try {
      while (true) {
        final pending = state.where((p) =>
            p.status == QueuedPhotoStatus.pending &&
            p.attempts < _maxAttempts);
        if (pending.isEmpty) break;
        final next = pending.first;

        // Gate on connectivity to avoid burning attempts while offline.
        final conn = await Connectivity().checkConnectivity();
        if (conn.contains(ConnectivityResult.none)) break;

        _update(next.id,
            (p) => p.copyWith(status: QueuedPhotoStatus.uploading));
        await _save();

        try {
          final file = File(next.localPath);
          if (!await file.exists()) {
            // File vanished — mark as failed so we stop looping.
            _update(next.id, (p) => p.copyWith(
                  status: QueuedPhotoStatus.failed,
                  lastError: 'Local file missing',
                ));
            await _save();
            continue;
          }
          await _repo.uploadPhotos(next.assignmentId, [file]);
          _update(next.id, (p) => p.copyWith(
                status: QueuedPhotoStatus.uploaded,
                clearError: true,
              ));
          await _save();
        } catch (e) {
          _update(next.id, (p) {
            final newAttempts = p.attempts + 1;
            return p.copyWith(
              status: newAttempts >= _maxAttempts
                  ? QueuedPhotoStatus.failed
                  : QueuedPhotoStatus.pending,
              attempts: newAttempts,
              lastError: e.toString(),
            );
          });
          await _save();
          // Short backoff before the next loop iteration.
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } finally {
      _processing = false;
    }
  }

  void _update(String id, QueuedPhoto Function(QueuedPhoto) mutate) {
    state = [
      for (final p in state)
        if (p.id == id) mutate(p) else p,
    ];
  }

}

final photoUploadQueueProvider =
    StateNotifierProvider<PhotoUploadQueueNotifier, List<QueuedPhoto>>((ref) {
  final repo = ref.watch(riderRepositoryProvider);
  final notifier = PhotoUploadQueueNotifier(repo);
  ref.onDispose(notifier.dispose);
  return notifier;
});
