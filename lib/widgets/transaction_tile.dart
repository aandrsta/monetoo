// lib/widgets/transaction_tile.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_toast.dart';
import '../utils/currency_formatter.dart';
import 'confirm_delete_sheet.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool showDate;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onDelete,
    required this.onEdit,
    this.showDate = false,
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
      confirmDismiss: (_) async => await ConfirmDeleteSheet.show(
        context,
        title: 'Hapus Transaksi?',
        description:
            'Transaksi ini akan dihapus permanen\ndan tidak bisa dikembalikan.',
      ),
      onDismissed: (_) {
        onDelete();
        // Toast is now handled by parent to avoid unmounted context warning
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
                      style: const TextStyle(fontSize: 20)),
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
                    showDate
                        ? '${DateFormatter.formatDayShort(transaction.date)} • ${DateFormatter.formatTime(transaction.date)}'
                        : DateFormatter.formatTime(transaction.date),
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
}
