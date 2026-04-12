// lib/widgets/icon_picker_dialog.dart

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/icon_data.dart';

class IconPickerDialog extends StatefulWidget {
  final String selectedIcon;
  final int selectedColor;

  const IconPickerDialog({
    super.key,
    required this.selectedIcon,
    required this.selectedColor,
  });

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedIcon;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final totalIcons = kAllIcons.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pilih Ikon',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary)),
                      Text('$totalIcons ikon tersedia',
                          style:
                              TextStyle(fontSize: 12, color: c.textSecondary)),
                    ],
                  ),
                  Row(
                    children: [
                      // Preview ikon yang sedang dipilih
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(widget.selectedColor)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                            child: Text(_selected,
                                style: const TextStyle(fontSize: 22))),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: c.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: c.divider),

            // ── Scrollable icon grid per grup ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: kIconGroups.length,
                itemBuilder: (_, groupIdx) {
                  final group = kIconGroups[groupIdx];
                  final groupIcons = (group['icons'] as List).cast<String>();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Heading grup
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          group['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: c.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Grid ikon
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: groupIcons.length,
                        itemBuilder: (_, i) {
                          final ic = groupIcons[i];
                          final isSel = _selected == ic;
                          return GestureDetector(
                            onTap: () {
                              // Langsung return hasil tanpa tombol konfirmasi
                              Navigator.pop(context, ic);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? Color(widget.selectedColor)
                                        .withValues(alpha: 0.18)
                                    : c.bgLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: isSel
                                        ? Color(widget.selectedColor)
                                        : Colors.transparent,
                                    width: 2),
                              ),
                              child: Center(
                                  child:
                                      Text(ic, style: const TextStyle(fontSize: 20))),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
