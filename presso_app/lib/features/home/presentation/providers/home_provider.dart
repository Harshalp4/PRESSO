import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presso_app/core/providers/app_config_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/home_repository.dart';
import '../../domain/models/daily_message_model.dart';
import '../../domain/models/home_data_model.dart'; // ActiveOrderSummary

// ─── Repository provider ────────────────────────────────────────────────────

// Must share the authenticated Dio from dioProvider — building a bare Dio
// here meant every home widget (coin balance, savings strip, active order)
// hit the API without a bearer token, got 401s, and silently fell through
// to the 0/empty fallback path. That's why My Coins detail showed 73 but
// the home card still showed 0.
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return HomeRepository(dio: dio);
});

// ─── Fallback suvichar list ──────────────────────────────────────────────────

final List<DailyMessageModel> fallbackSuvichars = [
  const DailyMessageModel(
    hindiText:
        'जो मन को शांत रखे, वही सच्चा ज्ञान है। स्वच्छता मन और घर दोनों की शोभा है।',
    englishText:
        'What keeps the mind calm is true wisdom. Cleanliness adorns both the mind and home.',
    category: 'motivation',
    date: '',
  ),
  const DailyMessageModel(
    hindiText:
        'हर सुबह एक नया अवसर लेकर आती है। ताजे कपड़ों की तरह, ताजे मन से शुरुआत करें।',
    englishText:
        'Every morning brings a new opportunity. Like fresh clothes, start with a fresh mind.',
    category: 'motivation',
    date: '',
  ),
  const DailyMessageModel(
    hindiText:
        'सफाई में ही भगवान का वास है। स्वच्छ वस्त्र, स्वच्छ विचार, स्वच्छ जीवन।',
    englishText:
        'God resides in cleanliness. Clean clothes, clean thoughts, clean life.',
    category: 'spiritual',
    date: '',
  ),
  const DailyMessageModel(
    hindiText:
        'समय का सदुपयोग करो। जो काम कल कर सकते हो, उसे आज ही निपटा लो।',
    englishText:
        'Make good use of time. Complete today what you can do tomorrow.',
    category: 'productivity',
    date: '',
  ),
  const DailyMessageModel(
    hindiText:
        'परिश्रम ही सफलता की कुंजी है। छोटे-छोटे कदम बड़ी मंजिल तक पहुँचाते हैं।',
    englishText:
        'Hard work is the key to success. Small steps lead to great destinations.',
    category: 'motivation',
    date: '',
  ),
  const DailyMessageModel(
    hindiText:
        'खुशी बाहर नहीं, अपने अंदर खोजो। एक मुस्कान से पूरा दिन बदल जाता है।',
    englishText:
        'Seek happiness within, not outside. A smile can change the entire day.',
    category: 'happiness',
    date: '',
  ),
  const DailyMessageModel(
    hindiText:
        'संगठित जीवन सुखी जीवन है। जब सब कुछ व्यवस्थित हो, तो मन प्रसन्न रहता है।',
    englishText:
        'An organized life is a happy life. When everything is in order, the mind stays joyful.',
    category: 'lifestyle',
    date: '',
  ),
  const DailyMessageModel(
    hindiText:
        'दूसरों की मदद करना ही सच्चा धर्म है। एक अच्छा काम पूरे दिन को पवित्र बना देता है।',
    englishText:
        'Helping others is true virtue. One good deed sanctifies the entire day.',
    category: 'spiritual',
    date: '',
  ),
  const DailyMessageModel(
    hindiText:
        'स्वास्थ्य ही सबसे बड़ा धन है। स्वच्छ वातावरण में ही स्वस्थ जीवन संभव है।',
    englishText:
        'Health is the greatest wealth. A healthy life is possible only in a clean environment.',
    category: 'health',
    date: '',
  ),
  const DailyMessageModel(
    hindiText:
        'आज का दिन फिर नहीं आएगा। इसलिए हर पल को पूरी तरह जियो और खुश रहो।',
    englishText:
        'Today will never come again. So live every moment fully and stay happy.',
    category: 'motivation',
    date: '',
  ),
];

// ─── Daily message provider ──────────────────────────────────────────────────

final dailyMessageProvider =
    FutureProvider<DailyMessageModel>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  final response = await repository.getDailyMessage();
  if (response.isSuccess && response.data != null) {
    return response.data!;
  }
  // Return a random fallback on API failure
  final now = DateTime.now();
  final index = now.day % fallbackSuvichars.length;
  return fallbackSuvichars[index];
});

// ─── AI tip provider ─────────────────────────────────────────────────────────

final aiTipProvider = FutureProvider<String>((ref) async {
  // getAiTip needs a BuildContext which is unavailable in a provider.
  // We call the Dio endpoint directly here using a time-context query param.
  final hour = DateTime.now().hour;
  String timeContext;
  String fallbackTip;

  if (hour >= 5 && hour < 12) {
    timeContext = 'morning';
    fallbackTip =
        'Morning is the best time to schedule a pickup. Book now for same-day processing and get your clothes back by evening!';
  } else if (hour >= 12 && hour < 17) {
    timeContext = 'afternoon';
    fallbackTip =
        'Schedule your laundry pickup this afternoon and receive fresh, pressed clothes delivered by tomorrow morning.';
  } else if (hour >= 17 && hour < 21) {
    timeContext = 'evening';
    fallbackTip =
        'Evening pickups are available! Our team can collect your clothes now and return them fresh within 24 hours.';
  } else {
    timeContext = 'night';
    fallbackTip =
        'Pre-schedule tomorrow\'s pickup tonight. Our early morning slots (8–10 AM) fill up fast — secure yours now!';
  }

  final repository = ref.watch(homeRepositoryProvider);
  try {
    final response = await repository.getRawAiTip(timeContext);
    if (response.isSuccess && response.data != null && response.data!.isNotEmpty) {
      return response.data!;
    }
  } catch (_) {
    // Fall through to fallback
  }
  return fallbackTip;
});

// ─── Active order provider ───────────────────────────────────────────────────

final activeOrderProvider =
    FutureProvider<ActiveOrderSummary?>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  final response = await repository.getActiveOrders();
  if (response.isSuccess && response.data != null) {
    final order = response.data!;
    if (order.orderId.isEmpty) return null;
    return order;
  }
  return null;
});

// ─── User savings provider ───────────────────────────────────────────────────

class SavingsState {
  final double totalSavings;
  final int orderCount;

  const SavingsState({
    required this.totalSavings,
    required this.orderCount,
  });
}

final userSavingsProvider = FutureProvider<SavingsState>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  final response = await repository.getUserSavings();
  if (response.isSuccess && response.data != null) {
    final data = response.data!;
    return SavingsState(
      totalSavings: (data['totalSaved'] as num?)?.toDouble() ??
          (data['total'] as num?)?.toDouble() ??
          0.0,
      orderCount: data['orderCount'] as int? ?? 0,
    );
  }
  return const SavingsState(totalSavings: 0.0, orderCount: 0);
});

// ─── Coin balance provider ───────────────────────────────────────────────────

class CoinState {
  final int balance;
  final String tier;
  final int coinsToNextTier;
  final String nextTierName;

  const CoinState({
    required this.balance,
    required this.tier,
    required this.coinsToNextTier,
    required this.nextTierName,
  });

  String get formattedBalance {
    if (balance >= 1000) {
      final thousands = balance ~/ 1000;
      final remainder = balance % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return balance.toString();
  }

  /// Compute rupee equivalent. Callers should pass [coinValueRupees]
  /// from [AppConfigState] for accuracy; default mirrors the DB seed.
  String rupeesEquivalentFor({double coinValueRupees = 0.1}) =>
      '₹${(balance * coinValueRupees).toStringAsFixed(0)}';

  /// Legacy getter — uses default rate.
  String get rupeesEquivalent => rupeesEquivalentFor();

  /// Compute progress toward next tier. Thresholds are parameterized so
  /// callers can pass values from [AppConfigState].
  double progressToNextTier({
    int goldThreshold = 500,
    int platinumThreshold = 1500,
    int diamondThreshold = 3000,
  }) {
    final Map<String, int> thresholds = {
      'Silver': 0,
      'Gold': goldThreshold,
      'Platinum': platinumThreshold,
      'Diamond': diamondThreshold,
    };
    final currentThreshold = thresholds[tier] ?? 0;
    final nextThreshold = thresholds[nextTierName] ?? platinumThreshold;
    if (nextThreshold <= currentThreshold) return 1.0;
    final progress = (balance - currentThreshold) /
        (nextThreshold - currentThreshold);
    return progress.clamp(0.0, 1.0);
  }
}

final coinBalanceProvider = FutureProvider<CoinState>((ref) async {
  final config = ref.watch(appConfigProvider);
  final goldT = config.loyaltyGoldThreshold;
  final platT = config.loyaltyPlatinumThreshold;
  final diamT = config.loyaltyDiamondThreshold;

  final repository = ref.watch(homeRepositoryProvider);
  final response = await repository.getCoinBalance();
  if (response.isSuccess && response.data != null) {
    final balance = response.data!;
    String tier = 'Silver';
    String nextTier = 'Gold';
    int toNext = goldT - balance;

    if (balance >= diamT) {
      tier = 'Diamond';
      nextTier = 'Diamond';
      toNext = 0;
    } else if (balance >= platT) {
      tier = 'Platinum';
      nextTier = 'Diamond';
      toNext = diamT - balance;
    } else if (balance >= goldT) {
      tier = 'Gold';
      nextTier = 'Platinum';
      toNext = platT - balance;
    } else {
      tier = 'Silver';
      nextTier = 'Gold';
      toNext = goldT - balance;
    }

    return CoinState(
      balance: balance,
      tier: tier,
      coinsToNextTier: toNext,
      nextTierName: nextTier,
    );
  }
  return const CoinState(
    balance: 0,
    tier: 'Silver',
    coinsToNextTier: 0,
    nextTierName: 'Gold',
  );
});

// ─── Services list provider ──────────────────────────────────────────────────

class ServiceItem {
  final String id;
  final String name;
  final String emoji;
  final String priceLabel;
  final String unit;
  final double startingPrice;
  final String? description;

  const ServiceItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.priceLabel,
    required this.unit,
    required this.startingPrice,
    this.description,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    final price = (json['pricePerPiece'] as num?)?.toDouble() ??
        (json['startingPrice'] as num?)?.toDouble() ??
        (json['basePrice'] as num?)?.toDouble() ??
        0.0;
    final name = json['name'] as String? ?? '';
    return ServiceItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: name,
      emoji: json['emoji'] as String? ?? _emojiForServiceName(name),
      priceLabel: json['priceLabel'] as String? ?? '\u{20B9}${price.toInt()}',
      unit: json['unit'] as String? ?? 'per piece',
      startingPrice: price,
      description: json['description'] as String?,
    );
  }

  /// Fallback emoji lookup by name — only used when DB emoji field is null.
  static String _emojiForServiceName(String name) {
    final n = name.toLowerCase();
    if (n.contains('wash') && n.contains('iron')) return '\u{1F455}'; // 👕
    if (n.contains('wash') && n.contains('fold')) return '\u{1F454}'; // 👔
    if (n.contains('dry')) return '\u{2728}';   // ✨
    if (n.contains('iron')) return '\u{2668}\u{FE0F}'; // ♨️
    if (n.contains('premium') || n.contains('hand')) return '\u{1F9F6}'; // 🧶
    if (n.contains('bed') || n.contains('pillow')) return '\u{1F6CC}'; // 🛌
    if (n.contains('curtain')) return '\u{1FA9F}'; // 🪟
    if (n.contains('saree') || n.contains('ethnic')) return '\u{1F97B}'; // 🥻
    if (n.contains('wool') || n.contains('winter')) return '\u{1F9E3}'; // 🧣
    if (n.contains('bag') || n.contains('leather')) return '\u{1F45C}'; // 👜
    if (n.contains('shoe')) return '\u{1F45F}'; // 👟
    return '\u{1F455}';
  }
}

final List<ServiceItem> _fallbackServices = [
  const ServiceItem(
    id: '10000000-0000-0000-0000-000000000001',
    name: 'Wash + Iron',
    emoji: '\u{1F455}', // 👕
    priceLabel: '\u{20B9}29',
    unit: 'per piece',
    startingPrice: 29,
    description: 'Machine wash + professional steam press',
  ),
  const ServiceItem(
    id: '10000000-0000-0000-0000-000000000002',
    name: 'Wash + Fold',
    emoji: '\u{1F454}', // 👔
    priceLabel: '\u{20B9}19',
    unit: 'per piece',
    startingPrice: 19,
    description: 'Machine wash + neatly folded, no ironing',
  ),
  const ServiceItem(
    id: '10000000-0000-0000-0000-000000000003',
    name: 'Dry Clean',
    emoji: '\u{2728}', // ✨
    priceLabel: '\u{20B9}149',
    unit: 'per piece',
    startingPrice: 149,
    description: 'Premium solvent-based, delicate fabrics',
  ),
  const ServiceItem(
    id: '10000000-0000-0000-0000-000000000004',
    name: 'Iron Only',
    emoji: '\u{2668}\u{FE0F}', // ♨️
    priceLabel: '\u{20B9}12',
    unit: 'per piece',
    startingPrice: 12,
    description: 'Professional steam press, no washing',
  ),
  const ServiceItem(
    id: '10000000-0000-0000-0000-000000000005',
    name: 'Premium Hand Wash',
    emoji: '\u{1F9F6}', // 🧶
    priceLabel: '\u{20B9}99',
    unit: 'per piece',
    startingPrice: 99,
    description: 'Hand wash for silk, wool, designer wear',
  ),
  const ServiceItem(
    id: '10000000-0000-0000-0000-00000000000b',
    name: 'Shoe Cleaning',
    emoji: '\u{1F45F}', // 👟
    priceLabel: '\u{20B9}199',
    unit: 'per pair',
    startingPrice: 199,
    description: 'Deep clean + deodorise, 48\u{2013}72 hrs',
  ),
];

final servicesListProvider =
    FutureProvider<List<ServiceItem>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  final response = await repository.getServices();
  if (response.isSuccess &&
      response.data != null &&
      response.data!.isNotEmpty) {
    return response.data!
        .map((json) => ServiceItem.fromJson(json))
        .toList();
  }
  return _fallbackServices;
});
