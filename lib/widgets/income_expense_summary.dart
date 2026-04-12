import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/currency_formatter.dart';

class IncomeExpenseSummary extends StatelessWidget {
  final double income;
  final double expense;

  const IncomeExpenseSummary({
    super.key,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final balance = income - expense;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _summaryBox(
            context,
            label: 'Masuk',
            amount: income,
            color: c.income,
            bgColor: c.incomeLight,
          ),
          const SizedBox(width: 8),
          _summaryBox(
            context,
            label: 'Keluar',
            amount: expense,
            color: c.expense,
            bgColor: c.expenseLight,
          ),
          const SizedBox(width: 8),
          _summaryBox(
            context,
            label: 'Saldo',
            amount: balance,
            color: c.accent,
            bgColor: c.bgLight,
          ),
        ],
      ),
    );
  }

  Widget _summaryBox(
    BuildContext context, {
    required String label,
    required double amount,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: color)),
            Text(
              CurrencyFormatter.formatCompact(amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
