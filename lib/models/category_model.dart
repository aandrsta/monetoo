// lib/models/category_model.dart

import 'transaction_model.dart';

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final int color;
  final TransactionType type;
  final bool isDefault;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type.name,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: map['color'],
      type: TransactionType.values.firstWhere((e) => e.name == map['type']),
      isDefault: map['isDefault'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    TransactionType? type,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Default categories
List<CategoryModel> getDefaultCategories() {
  final now = DateTime.now();
  return [
    // Expense categories
    CategoryModel(
        id: 'cat_makanan',
        name: 'Makanan & Minuman',
        icon: '🍜',
        color: 0xFFFF6B6B,
        type: TransactionType.expense,
        isDefault: true,
        createdAt: now),
    CategoryModel(
        id: 'cat_transport',
        name: 'Transportasi',
        icon: '🚗',
        color: 0xFF4ECDC4,
        type: TransactionType.expense,
        isDefault: true,
        createdAt: now),
    CategoryModel(
        id: 'cat_belanja',
        name: 'Belanja',
        icon: '🛍️',
        color: 0xFF45B7D1,
        type: TransactionType.expense,
        isDefault: true,
        createdAt: now),
    CategoryModel(
        id: 'cat_tagihan',
        name: 'Tagihan',
        icon: '💡',
        color: 0xFFFFBE0B,
        type: TransactionType.expense,
        isDefault: true,
        createdAt: now),
    CategoryModel(
        id: 'cat_kesehatan',
        name: 'Kesehatan',
        icon: '🏥',
        color: 0xFFFF6B6B,
        type: TransactionType.expense,
        isDefault: true,
        createdAt: now),
    CategoryModel(
        id: 'cat_hiburan',
        name: 'Hiburan',
        icon: '🎮',
        color: 0xFFA8E6CF,
        type: TransactionType.expense,
        isDefault: true,
        createdAt: now),
    CategoryModel(
        id: 'cat_pendidikan',
        name: 'Pendidikan',
        icon: '📚',
        color: 0xFF6C63FF,
        type: TransactionType.expense,
        isDefault: true,
        createdAt: now),
    CategoryModel(
        id: 'cat_lainnya_expense',
        name: 'Lainnya',
        icon: '📦',
        color: 0xFF9B9B9B,
        type: TransactionType.expense,
        isDefault: true,
        createdAt: now),

    // Income categories
    CategoryModel(
        id: 'cat_gaji',
        name: 'Gaji',
        icon: '💼',
        color: 0xFF51CF66,
        type: TransactionType.income,
        isDefault: true,
        createdAt: now),
    CategoryModel(
        id: 'cat_freelance',
        name: 'Freelance',
        icon: '💻',
        color: 0xFF339AF0,
        type: TransactionType.income,
        isDefault: true,
        createdAt: now),
    CategoryModel(
        id: 'cat_investasi',
        name: 'Investasi',
        icon: '📈',
        color: 0xFF20C997,
        type: TransactionType.income,
        isDefault: true,
        createdAt: now),
    CategoryModel(
        id: 'cat_hadiah',
        name: 'Hadiah / Bonus',
        icon: '🎁',
        color: 0xFFFF922B,
        type: TransactionType.income,
        isDefault: true,
        createdAt: now),
    CategoryModel(
        id: 'cat_lainnya_income',
        name: 'Lainnya',
        icon: '💰',
        color: 0xFF9B9B9B,
        type: TransactionType.income,
        isDefault: true,
        createdAt: now),
  ];
}
