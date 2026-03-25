// lib/screens/account_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/finance_provider.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_toast.dart';
import '../utils/currency_formatter.dart';
import '../widgets/add_transaction_bottom_sheet.dart';
import '../widgets/transaction_tile.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, provider, _) {
            final balance = provider.balance;
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Saldo keseluruhan',
                                  style: TextStyle(
                                      fontSize: 14, color: c.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(balance),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      balance >= 0 ? c.textPrimary : c.expense,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _editMode = !_editMode);
                              if (_editMode) {
                                AppToast.info(context, 'Ketuk akun untuk edit');
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _editMode
                                    ? c.accent
                                    : c.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _editMode
                                    ? Icons.edit_rounded
                                    : Icons.edit_outlined,
                                color: _editMode ? c.cardBg : c.accent,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_editMode) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: c.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: c.accent.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 16,
                                  color: c.accent.withValues(alpha: 0.8)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Mode edit aktif — ketuk akun untuk ubah atau hapus',
                                  style: TextStyle(
                                      fontSize: 12, color: c.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(child: _buildAccountsTab(provider)),
              ],
            );
          },
        ),
      ),
    );
  }

  double _getAccountBalance(FinanceProvider provider, String accountId) {
    final account = provider.accounts.firstWhere((a) => a.id == accountId);
    final txs = provider.transactions.where((t) => t.accountId == accountId);
    final income = txs
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = txs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    return account.openingBalance + income - expense;
  }

  Widget _buildAccountsTab(FinanceProvider provider) {
    final c = context.colors;
    final accounts = provider.accounts;
    final totalBal =
        accounts.fold(0.0, (s, a) => s + _getAccountBalance(provider, a.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Akun',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary)),
              Text(
                CurrencyFormatter.format(totalBal),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: totalBal >= 0 ? c.income : c.expense),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...accounts.map((a) => _buildAccountCard(a, provider)),
          const SizedBox(height: 8),
          _buildAddButton('Tambahkan akun',
              () => _showAccountSheet(context, null, AccountType.card)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAccountCard(AccountModel account, FinanceProvider provider) {
    final c = context.colors;
    final bal = _getAccountBalance(provider, account.id);
    final txCount =
        provider.transactions.where((t) => t.accountId == account.id).length;

    return GestureDetector(
      onTap: () {
        if (_editMode) {
          _showAccountSheet(context, account, account.type);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _AccountDetailScreen(account: account),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _editMode
              ? Color(account.color).withValues(alpha: 0.06)
              : c.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _editMode
                ? Color(account.color).withValues(alpha: 0.35)
                : Colors.transparent,
            width: _editMode ? 1.5 : 0,
          ),
          boxShadow: _editMode ? [] : c.cardShadow,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Color(account.color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                      child:
                          Text(account.icon, style: TextStyle(fontSize: 26))),
                ),
                if (_editMode)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.cardBg, width: 1.5),
                      ),
                      child: Icon(Icons.edit_rounded, size: 9, color: c.cardBg),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(account.name,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary)),
                    if (account.isPrimary) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.star, size: 14, color: Colors.amber),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    _editMode ? 'Ketuk untuk edit' : '$txCount transaksi',
                    style: TextStyle(
                        fontSize: 12,
                        color: _editMode
                            ? c.accent.withValues(alpha: 0.7)
                            : c.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(bal),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: bal >= 0 ? c.income : c.expense),
                ),
                const SizedBox(height: 3),
                Text(
                  bal >= 0 ? 'Surplus' : 'Defisit',
                  style: TextStyle(
                      fontSize: 11, color: bal >= 0 ? c.income : c.expense),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onTap) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.accent.withValues(alpha: 0.3), width: 2),
          boxShadow: c.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.add_rounded, color: c.accent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.accent)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountSheet(
      BuildContext context, AccountModel? existing, AccountType defaultType) {
    final c = context.colors;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final openingBalanceCtrl = TextEditingController(
        text: existing?.openingBalance != null && existing!.openingBalance != 0
            ? existing.openingBalance.toStringAsFixed(0)
            : '');
    String icon = existing?.icon ?? '💳';
    int color = existing?.color ?? 0xFF4169E1;
    AccountType type = existing?.type ?? defaultType;
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
      '💻',
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
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(ctx).size.height * 0.78,
          decoration: BoxDecoration(
            color: c.modalBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: c.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  existing == null ? 'Tambah akun' : 'Edit akun',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (existing == null) ...[
                        Text('Tipe',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                              child: _typeChip('Akun', AccountType.card, type,
                                  (t) => setModal(() => type = t))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _typeChip('Tunai', AccountType.cash, type,
                                  (t) => setModal(() => type = t))),
                        ]),
                        const SizedBox(height: 16),
                      ],
                      Text('Nama Akun',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameCtrl,
                        style: TextStyle(fontSize: 14, color: c.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Kartu, Tunai...',
                          prefixIcon: Text(icon,
                              style: TextStyle(fontSize: 20),
                              textAlign: TextAlign.center),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 48, maxWidth: 48),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        value: isPrimary,
                        onChanged: (v) =>
                            setModal(() => isPrimary = v ?? false),
                        title: Text('Akun Utama',
                            style:
                                TextStyle(fontSize: 14, color: c.textPrimary)),
                        subtitle: Text('Ditandai dengan bintang',
                            style: TextStyle(
                                fontSize: 12, color: c.textSecondary)),
                        contentPadding: EdgeInsets.zero,
                        activeColor: c.accent,
                      ),
                      const SizedBox(height: 16),
                      Text('Saldo Awal',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: openingBalanceCtrl,
                        style: TextStyle(fontSize: 14, color: c.textPrimary),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Rp 0',
                          prefixText: 'Rp ',
                          prefixStyle:
                              TextStyle(fontSize: 14, color: c.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Pilih Ikon',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: icons.map((ic) {
                          final sel = icon == ic;
                          return GestureDetector(
                            onTap: () => setModal(() => icon = ic),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: sel
                                    ? Color(color).withValues(alpha: 0.15)
                                    : c.bgLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color:
                                        sel ? Color(color) : Colors.transparent,
                                    width: 2),
                              ),
                              child: Center(
                                  child:
                                      Text(ic, style: TextStyle(fontSize: 22))),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text('Pilih Warna',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: colors.map((col) {
                          final sel = color == col;
                          return GestureDetector(
                            onTap: () => setModal(() => color = col),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(col),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: sel ? c.cardBg : Colors.transparent,
                                    width: 2),
                              ),
                              child: sel
                                  ? Icon(Icons.check_rounded,
                                      color: c.cardBg, size: 16)
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
                            onPressed: () =>
                                _confirmDeleteAccount(ctx, existing),
                            icon: Icon(Icons.delete_outline_rounded),
                            label: Text('Hapus Akun'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: c.expense,
                              side: BorderSide(color: c.expense),
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
                            if (nameCtrl.text.trim().isEmpty) {
                              AppToast.error(
                                  context, 'Nama akun tidak boleh kosong');
                              return;
                            }
                            final provider = context.read<FinanceProvider>();
                            double openingBalance = 0.0;
                            if (openingBalanceCtrl.text.isNotEmpty) {
                              openingBalance =
                                  double.tryParse(openingBalanceCtrl.text) ??
                                      0.0;
                            }
                            final account = AccountModel(
                              id: existing?.id ?? const Uuid().v4(),
                              name: nameCtrl.text.trim(),
                              type: type,
                              icon: icon,
                              color: color,
                              isPrimary: isPrimary,
                              openingBalance: openingBalance,
                              createdAt: existing?.createdAt ?? DateTime.now(),
                            );
                            if (existing == null) {
                              provider.addAccount(account);
                              Navigator.pop(ctx);
                              AppToast.success(
                                  context, 'Akun berhasil ditambahkan');
                            } else {
                              provider.updateAccount(account);
                              Navigator.pop(ctx);
                              AppToast.success(
                                  context, 'Akun berhasil diperbarui');
                              setState(() => _editMode = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(color),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            existing == null
                                ? 'Tambah akun'
                                : 'Simpan perubahan',
                            style: TextStyle(
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

  void _confirmDeleteAccount(BuildContext sheetCtx, AccountModel account) {
    final c = context.colors;
    showModalBottomSheet(
      context: sheetCtx,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: c.modalBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: c.divider, borderRadius: BorderRadius.circular(2)),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.expense.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: c.expense, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Hapus Akun?',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Akun "${account.name}" akan dihapus permanen.\nRiwayat transaksi tidak ikut terhapus.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: c.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: c.bgLight,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text('Batal',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: c.textSecondary)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final provider = context.read<FinanceProvider>();
                      provider.deleteAccount(account.id);
                      Navigator.pop(ctx);
                      Navigator.pop(sheetCtx);
                      AppToast.success(context, 'Akun berhasil dihapus');
                      setState(() => _editMode = false);
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: c.expense,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text('Hapus',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: c.cardBg)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, AccountType type, AccountType selected,
      Function(AccountType) onTap) {
    final c = context.colors;
    final isSel = type == selected;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? c.accent : c.bgLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSel ? c.cardBg : c.textSecondary)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ACCOUNT DETAIL SCREEN
// ─────────────────────────────────────────────

class _AccountDetailScreen extends StatefulWidget {
  final AccountModel account;
  const _AccountDetailScreen({required this.account});

  @override
  State<_AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<_AccountDetailScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, provider, _) {
            final allTx = provider.transactions
                .where((t) => t.accountId == widget.account.id)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            final filtered = _filter == 'income'
                ? allTx.where((t) => t.type == TransactionType.income).toList()
                : _filter == 'expense'
                    ? allTx
                        .where((t) => t.type == TransactionType.expense)
                        .toList()
                    : allTx;

            final income = allTx
                .where((t) => t.type == TransactionType.income)
                .fold(0.0, (s, t) => s + t.amount);
            final expense = allTx
                .where((t) => t.type == TransactionType.expense)
                .fold(0.0, (s, t) => s + t.amount);
            final balance = income - expense;

            return Column(
              children: [
                Container(
                  color: c.cardBg,
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.arrow_back_ios_new_rounded,
                                size: 20, color: c.textPrimary),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(widget.account.color)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                                child: Text(widget.account.icon,
                                    style: TextStyle(fontSize: 20))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(widget.account.name,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: c.textPrimary)),
                                  if (widget.account.isPrimary) ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.star,
                                        size: 13, color: Colors.amber),
                                  ],
                                ]),
                                Text('${allTx.length} transaksi',
                                    style: TextStyle(
                                        fontSize: 12, color: c.textSecondary)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(balance),
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: balance >= 0 ? c.income : c.expense),
                              ),
                              Text(
                                balance >= 0 ? 'Surplus' : 'Defisit',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: balance >= 0 ? c.income : c.expense),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: c.incomeLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Masuk',
                                    style: TextStyle(
                                        fontSize: 11, color: c.income)),
                                Text(
                                  CurrencyFormatter.formatCompact(income),
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: c.income),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: c.expenseLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Keluar',
                                    style: TextStyle(
                                        fontSize: 11, color: c.expense)),
                                Text(
                                  CurrencyFormatter.formatCompact(expense),
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: c.expense),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                Container(
                  color: c.cardBg,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _filterChip('all', 'Semua', Icons.list_rounded),
                        const SizedBox(width: 8),
                        _filterChip('income', 'Pemasukan',
                            Icons.arrow_downward_rounded),
                        const SizedBox(width: 8),
                        _filterChip('expense', 'Pengeluaran',
                            Icons.arrow_upward_rounded),
                      ],
                    ),
                  ),
                ),
                Container(height: 1, color: c.divider),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  size: 56, color: c.divider),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada transaksi\ndi akun ini',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: c.textSecondary,
                                    height: 1.5),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final tx = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TransactionTile(
                                transaction: tx,
                                onDelete: () {
                                  provider.deleteTransaction(tx.id);
                                  AppToast.success(
                                      context, 'Transaksi berhasil dihapus');
                                },
                                onEdit: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => AddTransactionBottomSheet(
                                      transaction: tx),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label, IconData icon) {
    final c = context.colors;
    final isSelected = _filter == value;
    Color color = c.accent;
    if (value == 'income') color = c.income;
    if (value == 'expense') color = c.expense;

    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : c.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : c.divider),
          boxShadow: isSelected ? [] : c.cardShadow,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? c.cardBg : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? c.cardBg : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
