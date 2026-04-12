import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/currency_formatter.dart';
import 'month_picker_dialog.dart';

class MonthSelectorBar extends StatelessWidget {
  final DateTime selectedMonth;
  final Function(DateTime) onChanged;

  const MonthSelectorBar({
    super.key,
    required this.selectedMonth,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => onChanged(
              DateTime(selectedMonth.year, selectedMonth.month - 1),
            ),
            icon: Icon(Icons.chevron_left_rounded, color: c.textPrimary),
          ),
          GestureDetector(
            onTap: () async {
              final picked = await MonthPickerDialog.show(context, selectedMonth);
              if (picked != null) {
                onChanged(picked);
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormatter.formatMonthYear(selectedMonth),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: c.textSecondary,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => onChanged(
              DateTime(selectedMonth.year, selectedMonth.month + 1),
            ),
            icon: Icon(Icons.chevron_right_rounded, color: c.textPrimary),
          ),
        ],
      ),
    );
  }
}
