import 'package:presso_app/features/services/domain/models/garment_type_model.dart';
import 'package:presso_app/features/services/domain/models/service_model.dart';
import 'package:presso_app/features/services/domain/models/service_treatment_model.dart';

// ============================================================================
// OFFLINE-ONLY FALLBACK DATA
//
// GUIDs here MUST match the EF Core seed data in the API project
// (ServiceConfiguration / GarmentTypeConfiguration / ServiceTreatmentConfiguration).
// If you change IDs here, update the API seed files too.
//
// Emojis here MUST match the DB seed data and the mockup.
// ============================================================================

const kFallbackServices = [
  // ── Clothes ──
  ServiceModel(
    id: '10000000-0000-0000-0000-000000000001',
    name: 'Wash + Iron',
    description: 'Machine wash + professional steam press',
    category: 'clothes',
    pricePerPiece: 29,
    emoji: '\u{1F455}', // 👕
    isActive: true,
    sortOrder: 1,
    garmentTypes: [
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000101', serviceId: '10000000-0000-0000-0000-000000000001', name: 'Shirt', emoji: '\u{1F455}', sortOrder: 1),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000102', serviceId: '10000000-0000-0000-0000-000000000001', name: 'T-Shirt', emoji: '\u{1F455}', sortOrder: 2),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000103', serviceId: '10000000-0000-0000-0000-000000000001', name: 'Pant / Jeans', emoji: '\u{1F456}', sortOrder: 3),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000104', serviceId: '10000000-0000-0000-0000-000000000001', name: 'Kurta', emoji: '\u{1F97B}', sortOrder: 4),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000105', serviceId: '10000000-0000-0000-0000-000000000001', name: 'Saree', emoji: '\u{1F97B}', priceOverride: 49, sortOrder: 5),
    ],
  ),
  ServiceModel(
    id: '10000000-0000-0000-0000-000000000002',
    name: 'Wash + Fold',
    description: 'Machine wash + neatly folded, no ironing',
    category: 'clothes',
    pricePerPiece: 19,
    emoji: '\u{1F454}', // 👔
    isActive: true,
    sortOrder: 2,
    garmentTypes: [
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000201', serviceId: '10000000-0000-0000-0000-000000000002', name: 'Shirt', emoji: '\u{1F455}', sortOrder: 1),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000202', serviceId: '10000000-0000-0000-0000-000000000002', name: 'T-Shirt', emoji: '\u{1F455}', sortOrder: 2),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000203', serviceId: '10000000-0000-0000-0000-000000000002', name: 'Pant / Jeans', emoji: '\u{1F456}', sortOrder: 3),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000204', serviceId: '10000000-0000-0000-0000-000000000002', name: 'Towel', emoji: '\u{1F9F4}', sortOrder: 4),
    ],
  ),
  ServiceModel(
    id: '10000000-0000-0000-0000-000000000003',
    name: 'Dry Clean',
    description: 'Premium solvent-based, delicate fabrics',
    category: 'clothes',
    pricePerPiece: 149,
    emoji: '\u{2728}', // ✨
    isActive: true,
    sortOrder: 3,
    garmentTypes: [
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000301', serviceId: '10000000-0000-0000-0000-000000000003', name: 'Suit (2pc)', emoji: '\u{1F935}', priceOverride: 349, sortOrder: 1),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000302', serviceId: '10000000-0000-0000-0000-000000000003', name: 'Blazer', emoji: '\u{1F9E5}', priceOverride: 249, sortOrder: 2),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000303', serviceId: '10000000-0000-0000-0000-000000000003', name: 'Jacket', emoji: '\u{1F9E5}', priceOverride: 299, sortOrder: 3),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000304', serviceId: '10000000-0000-0000-0000-000000000003', name: 'Saree (Silk)', emoji: '\u{1F97B}', priceOverride: 199, sortOrder: 4),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000305', serviceId: '10000000-0000-0000-0000-000000000003', name: 'Lehenga', emoji: '\u{1F457}', priceOverride: 499, sortOrder: 5),
    ],
  ),
  ServiceModel(
    id: '10000000-0000-0000-0000-000000000004',
    name: 'Iron Only',
    description: 'Professional steam press, no washing',
    category: 'clothes',
    pricePerPiece: 12,
    emoji: '\u{2668}\u{FE0F}', // ♨️
    isActive: true,
    sortOrder: 4,
    garmentTypes: [
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000401', serviceId: '10000000-0000-0000-0000-000000000004', name: 'Shirt', emoji: '\u{1F455}', sortOrder: 1),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000402', serviceId: '10000000-0000-0000-0000-000000000004', name: 'Pant / Jeans', emoji: '\u{1F456}', sortOrder: 2),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000403', serviceId: '10000000-0000-0000-0000-000000000004', name: 'Kurta', emoji: '\u{1F97B}', sortOrder: 3),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000404', serviceId: '10000000-0000-0000-0000-000000000004', name: 'Saree', emoji: '\u{1F97B}', priceOverride: 20, sortOrder: 4),
    ],
  ),
  ServiceModel(
    id: '10000000-0000-0000-0000-000000000005',
    name: 'Premium Hand Wash',
    description: 'Hand wash for silk, wool, designer wear',
    category: 'clothes',
    pricePerPiece: 99,
    emoji: '\u{1F9F6}', // 🧶
    isActive: true,
    sortOrder: 5,
    garmentTypes: [
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000501', serviceId: '10000000-0000-0000-0000-000000000005', name: 'Silk Garment', emoji: '\u{1F9F5}', sortOrder: 1),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000502', serviceId: '10000000-0000-0000-0000-000000000005', name: 'Woolen', emoji: '\u{1F9F6}', priceOverride: 129, sortOrder: 2),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000503', serviceId: '10000000-0000-0000-0000-000000000005', name: 'Delicate Fabric', emoji: '\u{1F9F5}', sortOrder: 3),
    ],
  ),

  // ── Home linen ──
  ServiceModel(
    id: '10000000-0000-0000-0000-000000000006',
    name: 'Bedsheet + Pillow Covers',
    description: 'Wash + iron, king/queen/single sizes',
    category: 'home_linen',
    pricePerPiece: 79,
    emoji: '\u{1F6CC}', // 🛌
    isActive: true,
    sortOrder: 6,
    garmentTypes: [
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000601', serviceId: '10000000-0000-0000-0000-000000000006', name: 'Single Bedsheet Set', emoji: '\u{1F6CF}\u{FE0F}', sortOrder: 1),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000602', serviceId: '10000000-0000-0000-0000-000000000006', name: 'Double Bedsheet Set', emoji: '\u{1F6CF}\u{FE0F}', priceOverride: 99, sortOrder: 2),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000603', serviceId: '10000000-0000-0000-0000-000000000006', name: 'King Bedsheet Set', emoji: '\u{1F6CF}\u{FE0F}', priceOverride: 119, sortOrder: 3),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000604', serviceId: '10000000-0000-0000-0000-000000000006', name: 'Pillow Cover (pair)', emoji: '\u{1F6CC}', priceOverride: 39, sortOrder: 4),
    ],
  ),
  ServiceModel(
    id: '10000000-0000-0000-0000-000000000007',
    name: 'Curtains + Drapes',
    description: 'Wash + iron, sized by panel count',
    category: 'home_linen',
    pricePerPiece: 149,
    emoji: '\u{1FA9F}', // 🪟
    isActive: true,
    sortOrder: 7,
    garmentTypes: [
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000701', serviceId: '10000000-0000-0000-0000-000000000007', name: 'Small Panel (< 5ft)', emoji: '\u{1FA9F}', sortOrder: 1),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000702', serviceId: '10000000-0000-0000-0000-000000000007', name: 'Medium Panel (5\u20137ft)', emoji: '\u{1FA9F}', priceOverride: 179, sortOrder: 2),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000703', serviceId: '10000000-0000-0000-0000-000000000007', name: 'Large Panel (> 7ft)', emoji: '\u{1FA9F}', priceOverride: 229, sortOrder: 3),
    ],
  ),

  // ── Specialty ──
  ServiceModel(
    id: '10000000-0000-0000-0000-000000000008',
    name: 'Saree + Ethnic Wear',
    description: 'Hand wash / dry clean + careful pressing',
    category: 'specialty',
    pricePerPiece: 99,
    emoji: '\u{1F97B}', // 🥻
    isActive: true,
    sortOrder: 8,
    garmentTypes: [
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000801', serviceId: '10000000-0000-0000-0000-000000000008', name: 'Cotton Saree', emoji: '\u{1F97B}', sortOrder: 1),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000802', serviceId: '10000000-0000-0000-0000-000000000008', name: 'Silk Saree', emoji: '\u{1F97B}', priceOverride: 199, sortOrder: 2),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000803', serviceId: '10000000-0000-0000-0000-000000000008', name: 'Lehenga / Sherwani', emoji: '\u{1F457}', priceOverride: 349, sortOrder: 3),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000804', serviceId: '10000000-0000-0000-0000-000000000008', name: 'Ethnic Kurta Set', emoji: '\u{1F97B}', priceOverride: 149, sortOrder: 4),
    ],
  ),
  ServiceModel(
    id: '10000000-0000-0000-0000-000000000009',
    name: 'Woolen + Winter Wear',
    description: 'Sweaters, blankets, jackets \u2014 gentle care',
    category: 'specialty',
    pricePerPiece: 149,
    emoji: '\u{1F9E3}', // 🧣
    isActive: true,
    sortOrder: 9,
    garmentTypes: [
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000901', serviceId: '10000000-0000-0000-0000-000000000009', name: 'Sweater', emoji: '\u{1F9E3}', sortOrder: 1),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000902', serviceId: '10000000-0000-0000-0000-000000000009', name: 'Jacket / Coat', emoji: '\u{1F9E5}', priceOverride: 249, sortOrder: 2),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000000903', serviceId: '10000000-0000-0000-0000-000000000009', name: 'Blanket', emoji: '\u{1F9E3}', priceOverride: 299, sortOrder: 3),
    ],
  ),
  ServiceModel(
    id: '10000000-0000-0000-0000-00000000000a',
    name: 'Bags + Leather Goods',
    description: 'Handbags, backpacks, leather accessories',
    category: 'specialty',
    pricePerPiece: 299,
    emoji: '\u{1F45C}', // 👜
    isActive: true,
    sortOrder: 10,
    garmentTypes: [
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000001001', serviceId: '10000000-0000-0000-0000-00000000000a', name: 'Handbag', emoji: '\u{1F45C}', sortOrder: 1),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000001002', serviceId: '10000000-0000-0000-0000-00000000000a', name: 'Backpack', emoji: '\u{1F392}', priceOverride: 249, sortOrder: 2),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000001003', serviceId: '10000000-0000-0000-0000-00000000000a', name: 'Wallet / Belt', emoji: '\u{1F45B}', priceOverride: 149, sortOrder: 3),
    ],
    treatments: [
      ServiceTreatmentModel(id: '30000000-0000-0000-0000-000000000001', name: 'Clean Only', description: 'Surface clean + conditioning', priceMultiplier: 1.0, sortOrder: 1, tags: ['Surface clean', 'Conditioning', '24-48 hrs']),
      ServiceTreatmentModel(id: '30000000-0000-0000-0000-000000000002', name: 'Deep Clean', description: 'Deep clean + color restoration', priceMultiplier: 1.5, sortOrder: 2, tags: ['Deep clean', 'Color restoration', '48-72 hrs']),
      ServiceTreatmentModel(id: '30000000-0000-0000-0000-000000000003', name: 'Full Restore', description: 'Full restoration + waterproofing', priceMultiplier: 2.0, sortOrder: 3, tags: ['Full restoration', 'Waterproofing', '72+ hrs']),
    ],
  ),

  // ── Shoe cleaning (dedicated flow) ──
  ServiceModel(
    id: '10000000-0000-0000-0000-00000000000b',
    name: 'Shoe Cleaning',
    description: 'Deep clean + deodorise, 48\u201372 hrs',
    category: 'specialty',
    pricePerPiece: 199,
    emoji: '\u{1F45F}', // 👟
    isActive: true,
    sortOrder: 11,
    garmentTypes: [
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000001101', serviceId: '10000000-0000-0000-0000-00000000000b', name: 'Sneakers', emoji: '\u{1F45F}', sortOrder: 1),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000001102', serviceId: '10000000-0000-0000-0000-00000000000b', name: 'Leather Shoes', emoji: '\u{1F45E}', priceOverride: 249, sortOrder: 2),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000001103', serviceId: '10000000-0000-0000-0000-00000000000b', name: 'Sandals', emoji: '\u{1FA74}', priceOverride: 149, sortOrder: 3),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000001104', serviceId: '10000000-0000-0000-0000-00000000000b', name: 'Heels', emoji: '\u{1F460}', priceOverride: 199, sortOrder: 4),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000001105', serviceId: '10000000-0000-0000-0000-00000000000b', name: 'Boots / Ankle Boots', emoji: '\u{1F97E}', priceOverride: 299, sortOrder: 5),
      GarmentTypeModel(id: '20000000-0000-0000-0000-000000001106', serviceId: '10000000-0000-0000-0000-00000000000b', name: 'Ethnic / Kolhapuri', emoji: '\u{1F97F}', priceOverride: 179, sortOrder: 6),
    ],
    treatments: [
      ServiceTreatmentModel(id: '30000000-0000-0000-0000-000000000004', name: 'Basic Clean', description: 'Surface clean + deodorize', priceMultiplier: 1.0, sortOrder: 1, tags: ['Exterior clean', 'Deodorise', '24-48 hrs']),
      ServiceTreatmentModel(id: '30000000-0000-0000-0000-000000000005', name: 'Deep Clean', description: 'Deep clean + stain removal + deodorize', priceMultiplier: 1.5, sortOrder: 2, tags: ['Deep clean', 'Stain removal', 'Sole whitening', '48-72 hrs']),
      ServiceTreatmentModel(id: '30000000-0000-0000-0000-000000000006', name: 'Premium Restore', description: 'Full restore + sole whitening + protection', priceMultiplier: 2.0, sortOrder: 3, tags: ['Full restore', 'Unyellowing', 'Protection coat', '72+ hrs']),
    ],
  ),
];
