import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class TransactionFilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onChanged;

  const TransactionFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _filterChip(context, 'all', 'Semua', Icons.list_rounded),
          const SizedBox(width: 8),
          _filterChip(context, 'income', 'Pemasukan', Icons.arrow_downward_rounded),
          const SizedBox(width: 8),
          _filterChip(context, 'expense', 'Pengeluaran', Icons.arrow_upward_rounded),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, String value, String label, IconData icon) {
    final c = context.colors;
    final isSelected = selectedFilter == value;
    Color color = c.accent;
    if (value == 'income') color = c.income;
    if (value == 'expense') color = c.expense;

    return GestureDetector(
      onTap: () => onChanged(value),
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
