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
import '../widgets/edit_mode_widgets.dart';
import '../widgets/income_expense_summary.dart';
import '../widgets/transaction_filter_chips.dart';
import '../widgets/confirm_delete_sheet.dart';
import '../widgets/common/bottom_sheet_handle.dart';
import 'account_detail_screen.dart';

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
                          EditModeButton(
                            isEditMode: _editMode,
                            onTap: () {
                              setState(() => _editMode = !_editMode);
                              if (_editMode) {
                                AppToast.info(context, 'Ketuk akun untuk edit');
                              }
                            },
                          ),
                        ],
                      ),
                      if (_editMode) ...[
                        const SizedBox(height: 12),
                        const EditModeBanner(
                          message: 'Mode edit aktif — ketuk akun untuk ubah atau hapus',
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
    final txs = provider.transactions.where((t) => t.accountId == accountId).toList();
    return account.openingBalance + txs.balance;
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
              builder: (_) => AccountDetailScreen(account: account),
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
              const Center(
                child: BottomSheetHandle(),
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
                            onPressed: () async {
                              final confirmed = await ConfirmDeleteSheet.show(
                                context,
                                title: 'Hapus Akun?',
                                description: 'Akun "${account.name}" akan dihapus permanen.\nRiwayat transaksi tidak ikut terhapus.',
                              );
                              if (confirmed == true) {
                                final provider = context.read<FinanceProvider>();
                                provider.deleteAccount(account.id);
                                Navigator.pop(ctx);
                                AppToast.success(context, 'Akun berhasil dihapus');
                                setState(() => _editMode = false);
                              }
                            },
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

