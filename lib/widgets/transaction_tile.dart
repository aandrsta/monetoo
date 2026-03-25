// lib/widgets/transaction_tile.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_colors.dart';
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
    final c = context.colors;
    final isIncome = transaction.type == TransactionType.income;

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
          color: c.expense,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_rounded, color: c.cardBg),
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
            color: c.cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: c.cardShadow,
          ),
          child: Row(
            children: [
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
                      style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.categoryName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (account != null || hasNote) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
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
                                      style: TextStyle(fontSize: 10)),
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
                          if (hasNote)
                            Flexible(
                              child: Text(
                                transaction.note!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: c.textSecondary,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${CurrencyFormatter.formatCompact(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isIncome ? c.income : c.expense,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatTime(transaction.date),
                    style: TextStyle(
                      fontSize: 10,
                      color: c.textSecondary,
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
    final c = context.colors;
    return showModalBottomSheet<bool>(
      context: context,
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
                  shape: BoxShape.circle),
              child: Icon(Icons.delete_outline_rounded,
                  color: c.expense, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Hapus Transaksi?',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Transaksi ini akan dihapus permanen\ndan tidak bisa dikembalikan.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: c.textSecondary, height: 1.5),
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
                          color: c.bgLight,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                          child: Text('Batal',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: c.textSecondary))),
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
                          color: c.expense,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                          child: Text('Hapus',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: c.cardBg))),
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
