import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PhotoProofStrip extends StatelessWidget {
  final List<String> photoUrls;
  final int maxVisible;
  final VoidCallback? onViewAll;

  const PhotoProofStrip({
    super.key,
    required this.photoUrls,
    this.maxVisible = 4,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) {
      return _EmptyPhotoStrip();
    }

    final visible = photoUrls.take(maxVisible).toList();
    final remaining = photoUrls.length - maxVisible;

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showPhotoViewer(context, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: visible[index],
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _photoPlaceholder(),
                      errorWidget: (_, __, ___) => _photoPlaceholder(),
                    ),
                  ),
                );
              },
            ),
          ),
          if (remaining > 0) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '+$remaining',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text(
                      'more',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_outlined,
        size: 20,
        color: AppColors.textHint,
      ),
    );
  }

  void _showPhotoViewer(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _PhotoViewerDialog(
        photoUrls: photoUrls,
        initialIndex: initialIndex,
      ),
    );
  }
}

class _EmptyPhotoStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (int i = 0; i < 4; i++) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.border,
                  width: 0.5,
                ),
              ),
              child: const Icon(
                Icons.photo_camera_outlined,
                size: 18,
                color: AppColors.textHint,
              ),
            ),
            if (i < 3) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _PhotoViewerDialog extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;

  const _PhotoViewerDialog({
    required this.photoUrls,
    required this.initialIndex,
  });

  @override
  State<_PhotoViewerDialog> createState() => _PhotoViewerDialogState();
}

class _PhotoViewerDialogState extends State<_PhotoViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photoUrls.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (_, index) {
                return Center(
                  child: InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: widget.photoUrls[index],
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textHint,
                        size: 60,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 48,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0x99000000),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.photoUrls.length,
                  (i) => Container(
                    width: _currentIndex == i ? 20 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _currentIndex == i
                          ? AppColors.primary
                          : AppColors.textHint,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
