import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// A reusable dialog to pick year and month.
/// Returns the selected [DateTime] or null if cancelled.
class MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const MonthPickerDialog({
    super.key,
    required this.initialDate,
  });

  static Future<DateTime?> show(BuildContext context, DateTime initialDate) {
    return showDialog<DateTime>(
      context: context,
      builder: (context) => MonthPickerDialog(initialDate: initialDate),
    );
  }

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late int _pickedYear;
  late int _pickedMonth;

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  @override
  void initState() {
    super.initState();
    _pickedYear = widget.initialDate.year;
    _pickedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AlertDialog(
      backgroundColor: c.modalBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Pilih Bulan',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
        ),
      ),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _pickedYear--),
                  icon: Icon(Icons.chevron_left_rounded, color: c.textPrimary),
                ),
                Text(
                  '$_pickedYear',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _pickedYear++),
                  icon: Icon(Icons.chevron_right_rounded, color: c.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (_, i) {
                final m = i + 1;
                final isSelected = m == _pickedMonth;
                return GestureDetector(
                  onTap: () => setState(() => _pickedMonth = m),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? c.accent : c.bgLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _months[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? c.cardBg : c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal', style: TextStyle(color: c.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, DateTime(_pickedYear, _pickedMonth)),
          child: Text('Pilih', style: TextStyle(color: c.accent)),
        ),
      ],
    );
  }
}
