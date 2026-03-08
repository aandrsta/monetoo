// lib/models/account_model.dart

enum AccountType {
  cash,
  card,
  savings,
}

class AccountModel {
  final String id;
  final String name;
  final AccountType type;
  final String icon;
  final int color;
  final bool isPrimary;
  final DateTime createdAt;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isPrimary = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'icon': icon,
      'color': color,
      'isPrimary': isPrimary ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: map['color'],
      type: AccountType.values.firstWhere((e) => e.name == map['type']),
      isPrimary: map['isPrimary'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  AccountModel copyWith({
    String? id,
    String? name,
    AccountType? type,
    String? icon,
    int? color,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Default accounts
List<AccountModel> getDefaultAccounts() {
  final now = DateTime.now();
  return [
    AccountModel(
      id: 'acc_kartu',
      name: 'Kartu',
      type: AccountType.card,
      icon: '💳',
      color: 0xFF4169E1,
      isPrimary: true,
      createdAt: now,
    ),
    AccountModel(
      id: 'acc_tunai',
      name: 'Tunai',
      type: AccountType.cash,
      icon: '💵',
      color: 0xFF00D4AA,
      isPrimary: false,
      createdAt: now,
    ),
  ];
}
