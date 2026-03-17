// lib/widgets/transaction_tile.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_toast.dart';
import '../utils/currency_formatter.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;

    // Ambil nama akun dari provider
    final accounts = context.watch<FinanceProvider>().accounts;
    final account = transaction.accountId != null
        ? accounts.where((a) => a.id == transaction.accountId).firstOrNull
        : null;

    final hasNote =
        transaction.note != null && transaction.note!.trim().isNotEmpty;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.expense,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async => await _showDeleteConfirm(context),
      onDismissed: (_) {
        onDelete();
        AppToast.success(context, 'Transaksi berhasil dihapus');
      },
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              // Ikon kategori
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      Color(transaction.categoryColor).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(transaction.categoryIcon,
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),

              // Teks tengah
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul
                    Text(
                      transaction.categoryName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Baris kedua: akun pill + catatan (kalau ada)
                    // Kalau tidak ada keduanya → tidak tampil apapun
                    if (account != null || hasNote) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          // Pill akun
                          if (account != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(account.color)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(account.icon,
                                      style: const TextStyle(fontSize: 10)),
                                  const SizedBox(width: 3),
                                  Text(
                                    account.name,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Color(account.color),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasNote) const SizedBox(width: 6),
                          ],
                          // Catatan — hanya kalau ada
                          if (hasNote)
                            Flexible(
                              child: Text(
                                transaction.note!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Nominal + waktu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${CurrencyFormatter.formatCompact(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isIncome ? AppTheme.income : AppTheme.expense,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatTime(transaction.date),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: AppTheme.expense.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.expense, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Hapus Transaksi?',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              'Transaksi ini akan dihapus permanen\ndan tidak bisa dikembalikan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: AppTheme.bgLight,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                          child: Text('Batal',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: AppTheme.expense,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                          child: Text('Hapus',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white))),
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
}
