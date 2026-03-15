// lib/widgets/transaction_tile.dart

import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../utils/app_theme.dart';
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
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Hapus Transaksi?',
                style: TextStyle(fontWeight: FontWeight.w600)),
            content: Text(
              'Transaksi "${transaction.title}" akan dihapus.',
              style: const TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus',
                    style: TextStyle(color: AppTheme.expense)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      Color(transaction.categoryColor).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    transaction.categoryIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.categoryName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (transaction.note != null &&
                        transaction.note!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        transaction.note!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Color(transaction.categoryColor)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          transaction.categoryName,
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(transaction.categoryColor),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
}
