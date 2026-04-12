// lib/widgets/category_edit_sheet.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_toast.dart';
import '../utils/icon_data.dart';
import 'icon_picker_dialog.dart';
import 'common/bottom_sheet_handle.dart';
import 'confirm_delete_category_sheet.dart';

class CategoryEditSheet extends StatefulWidget {
  final CategoryModel? existing;
  final TransactionType defaultType;
  final VoidCallback onSaved;

  const CategoryEditSheet({
    super.key,
    this.existing,
    required this.defaultType,
    required this.onSaved,
  });

  static void show(BuildContext context, {CategoryModel? existing, required TransactionType defaultType, required VoidCallback onSaved}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryEditSheet(
        existing: existing,
        defaultType: defaultType,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends State<CategoryEditSheet> {
  late TextEditingController _nameCtrl;
  late String _selectedIcon;
  late int _selectedColor;
  late TransactionType _selectedType;

  final List<int> _colors = [
    0xFFFF6B6B,
    0xFFFF5C7A,
    0xFFFFBE0B,
    0xFFFF922B,
    0xFF51CF66,
    0xFF00D4AA,
    0xFF20C997,
    0xFF4ECDC4,
    0xFF339AF0,
    0xFF45B7D1,
    0xFF6C63FF,
    0xFF9D85FF,
    0xFF7C6FFF,
    0xFFA8E6CF,
    0xFF9B9B9B,
    0xFF5C7080,
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _selectedIcon = widget.existing?.icon ?? '📦';
    _selectedColor = widget.existing?.color ?? 0xFF7C6FFF;
    _selectedType = widget.existing?.type ?? widget.defaultType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: BottomSheetHandle()),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              widget.existing == null ? 'Tambah kategori' : 'Edit kategori',
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
                  // Tipe
                  if (widget.existing == null) ...[
                    const Text('Tipe',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: _catTypeChip(
                          'Pengeluaran',
                          TransactionType.expense,
                          _selectedType,
                          c.expense,
                          (t) => setState(() => _selectedType = t),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _catTypeChip(
                          'Pemasukan',
                          TransactionType.income,
                          _selectedType,
                          c.income,
                          (t) => setState(() => _selectedType = t),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  // Nama
                  const Text('Nama Kategori',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Kuliner, Transport...',
                      prefixIcon: Text(_selectedIcon,
                          style: const TextStyle(fontSize: 20),
                          textAlign: TextAlign.center),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 48, maxWidth: 48),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol acak
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final rng = Random();
                        setState(() {
                          _selectedIcon =
                              kAllIcons[rng.nextInt(kAllIcons.length)];
                          _selectedColor =
                              _colors[rng.nextInt(_colors.length)];
                        });
                      },
                      icon: const Icon(Icons.shuffle_rounded),
                      label: const Text('Acak Ikon & Warna'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.accent,
                        side: BorderSide(color: c.accent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Ikon
                  const Text('Pilih Ikon',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (_) => IconPickerDialog(
                          selectedIcon: _selectedIcon,
                          selectedColor: _selectedColor,
                        ),
                      );
                      if (result != null) {
                        setState(() => _selectedIcon = result);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: c.bgLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(_selectedColor).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Color(_selectedColor)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(_selectedIcon,
                                  style: const TextStyle(fontSize: 28)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ikon terpilih',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: c.textSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  '${kAllIcons.length} ikon tersedia — ketuk untuk ganti',
                                  style: TextStyle(
                                      fontSize: 12, color: c.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: c.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Ganti',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: c.accent)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Warna
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pilih Warna',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${_colors.length} warna',
                          style: TextStyle(
                              fontSize: 11, color: c.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: _colors.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setState(() => _selectedColor = _colors[i]),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(_colors[i]),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _selectedColor == _colors[i]
                                  ? c.cardBg
                                  : Colors.transparent,
                              width: 2),
                          boxShadow: _selectedColor == _colors[i]
                              ? [
                                  BoxShadow(
                                      color: Color(_colors[i])
                                          .withValues(alpha: 0.5),
                                      blurRadius: 8)
                                ]
                              : [],
                        ),
                        child: _selectedColor == _colors[i]
                            ? Icon(Icons.check_rounded,
                                color: c.cardBg, size: 16)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Hapus
                  if (widget.existing != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => ConfirmDeleteCategorySheet.show(
                            context, widget.existing!, onDeleted: widget.onSaved),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Hapus Kategori'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.expense,
                          side: BorderSide(color: c.expense),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Simpan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_nameCtrl.text.trim().isEmpty) {
                          AppToast.error(
                              context, 'Nama kategori tidak boleh kosong');
                          return;
                        }
                        final provider = context.read<FinanceProvider>();
                        final category = CategoryModel(
                          id: widget.existing?.id ?? const Uuid().v4(),
                          name: _nameCtrl.text.trim(),
                          icon: _selectedIcon,
                          color: _selectedColor,
                          type: widget.existing?.type ?? _selectedType,
                          isDefault: widget.existing?.isDefault ?? false,
                          createdAt: widget.existing?.createdAt ?? DateTime.now(),
                        );
                        if (widget.existing == null) {
                          provider.addCategory(category);
                          Navigator.pop(context);
                          AppToast.success(
                              context, 'Kategori berhasil ditambahkan');
                        } else {
                          provider.updateCategory(category);
                          Navigator.pop(context);
                          AppToast.success(
                              context, 'Kategori berhasil diperbarui');
                        }
                        widget.onSaved();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(_selectedColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        widget.existing == null
                            ? 'Tambah kategori'
                            : 'Simpan Perubahan',
                        style: const TextStyle(
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
    );
  }

  Widget _catTypeChip(
    String label,
    TransactionType type,
    TransactionType selected,
    Color color,
    Function(TransactionType) onTap,
  ) {
    final c = context.colors;
    final isSel = type == selected;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? color : c.bgLight,
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
