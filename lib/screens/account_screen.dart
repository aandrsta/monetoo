// lib/screens/account_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/finance_provider.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, provider, _) {
            final balance = provider.balance;

            return Column(
              children: [
                // Header with total balance
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Saldo keseluruhan',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormatter.format(balance),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: balance >= 0
                                ? AppTheme.textPrimary
                                : AppTheme.expense,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _buildAccountsTab(provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Calculate balance for a specific account based on its transactions
  double _getAccountBalance(FinanceProvider provider, String accountId) {
    final accountTransactions =
        provider.transactions.where((t) => t.accountId == accountId).toList();

    double income = accountTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
    double expense = accountTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);

    return income - expense;
  }

  Widget _buildAccountsTab(FinanceProvider provider) {
    final regularAccounts = provider.regularAccounts;
    final savingsAccounts = provider.savingsAccounts;

    // Total balance across all accounts
    double totalBalance = 0;
    for (final acc in [...regularAccounts, ...savingsAccounts]) {
      totalBalance += _getAccountBalance(provider, acc.id);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── REGULAR ACCOUNTS ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Akun',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                CurrencyFormatter.format(
                  regularAccounts.fold(
                    0.0,
                    (sum, acc) => sum + _getAccountBalance(provider, acc.id),
                  ),
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.income,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...regularAccounts.map(
            (account) => _buildAccountCard(account, provider),
          ),
          const SizedBox(height: 8),
          _buildAddButton(
            'Tambahkan akun keuangan',
            () => _showAddAccountSheet(context, AccountType.card),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(AccountModel account, FinanceProvider provider) {
    final accountBalance = _getAccountBalance(provider, account.id);

    // Get transaction counts for this account
    final txCount =
        provider.transactions.where((t) => t.accountId == account.id).length;

    return GestureDetector(
      onLongPress: () => _showEditAccountSheet(context, account),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Color(account.color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  account.icon,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (account.isPrimary) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$txCount transaksi',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(accountBalance),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: accountBalance >= 0
                        ? AppTheme.income
                        : AppTheme.expense,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  accountBalance >= 0 ? 'Surplus' : 'Defisit',
                  style: TextStyle(
                    fontSize: 11,
                    color: accountBalance >= 0
                        ? AppTheme.income
                        : AppTheme.expense,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accent.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppTheme.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAccountSheet(BuildContext context, [AccountType? defaultType]) {
    _showAccountSheet(context, null, defaultType ?? AccountType.card);
  }

  void _showEditAccountSheet(BuildContext context, AccountModel account) {
    _showAccountSheet(context, account, account.type);
  }

  void _showAccountSheet(
      BuildContext context, AccountModel? existing, AccountType defaultType) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    String selectedIcon = existing?.icon ?? '💳';
    int selectedColor = existing?.color ?? 0xFF4169E1;
    AccountType selectedType = existing?.type ?? defaultType;
    bool isPrimary = existing?.isPrimary ?? false;

    final icons = [
      '💳',
      '💵',
      '💰',
      '🏦',
      '💎',
      '🎯',
      '🏠',
      '🚗',
      '✈️',
      '🎁',
      '📱',
      '💻'
    ];
    final colors = [
      0xFF4169E1,
      0xFF00D4AA,
      0xFFFF6B6B,
      0xFFFFBE0B,
      0xFF7C6FFF,
      0xFFFF5C7A,
      0xFF51CF66,
      0xFF45B7D1,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  existing == null ? 'Tambah akun' : 'Edit akun',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (existing == null) ...[
                        const Text('Tipe',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _typeChip(
                                  'Akun',
                                  AccountType.card,
                                  selectedType,
                                  (t) => setModalState(() => selectedType = t)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _typeChip(
                                  'Tunai',
                                  AccountType.cash,
                                  selectedType,
                                  (t) => setModalState(() => selectedType = t)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _typeChip(
                                  'Tabungan',
                                  AccountType.savings,
                                  selectedType,
                                  (t) => setModalState(() => selectedType = t)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text('Nama Akun',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Kartu, Tunai...',
                          prefixIcon: Text(selectedIcon,
                              style: const TextStyle(fontSize: 20),
                              textAlign: TextAlign.center),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 48, maxWidth: 48),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        value: isPrimary,
                        onChanged: (val) =>
                            setModalState(() => isPrimary = val ?? false),
                        title: const Text('Akun Utama',
                            style: TextStyle(fontSize: 14)),
                        subtitle: const Text('Ditandai dengan bintang',
                            style: TextStyle(fontSize: 12)),
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppTheme.accent,
                      ),
                      const SizedBox(height: 16),
                      const Text('Pilih Ikon',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: icons.map((icon) {
                          final isSelected = selectedIcon == icon;
                          return GestureDetector(
                            onTap: () =>
                                setModalState(() => selectedIcon = icon),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Color(selectedColor)
                                        .withValues(alpha: 0.15)
                                    : AppTheme.bgLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? Color(selectedColor)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                  child: Text(icon,
                                      style: const TextStyle(fontSize: 22))),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('Pilih Warna',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: colors.map((color) {
                          final isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () =>
                                setModalState(() => selectedColor = color),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(color),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 16)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      if (existing != null) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final provider = context.read<FinanceProvider>();
                              provider.deleteAccount(existing.id);
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Hapus Akun'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.expense,
                              side: const BorderSide(color: AppTheme.expense),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (nameController.text.isEmpty) return;
                            final provider = context.read<FinanceProvider>();
                            final account = AccountModel(
                              id: existing?.id ?? const Uuid().v4(),
                              name: nameController.text.trim(),
                              type: selectedType,
                              icon: selectedIcon,
                              color: selectedColor,
                              isPrimary: isPrimary,
                              createdAt: existing?.createdAt ?? DateTime.now(),
                            );

                            if (existing == null) {
                              provider.addAccount(account);
                            } else {
                              provider.updateAccount(account);
                            }
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(selectedColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            existing == null
                                ? 'Tambah akun'
                                : 'Simpan perubahan',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String label, AccountType type, AccountType selected,
      Function(AccountType) onTap) {
    final isSelected = type == selected;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : AppTheme.bgLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
