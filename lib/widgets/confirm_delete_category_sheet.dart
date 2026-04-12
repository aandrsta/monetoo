// lib/widgets/confirm_delete_category_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_toast.dart';

class ConfirmDeleteCategorySheet extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onDeleted;

  const ConfirmDeleteCategorySheet({
    super.key,
    required this.category,
    required this.onDeleted,
  });

  static void show(BuildContext context, CategoryModel category, {required VoidCallback onDeleted}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfirmDeleteCategorySheet(category: category, onDeleted: onDeleted),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
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
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delete_outline_rounded,
                color: c.expense, size: 28),
          ),
          const SizedBox(height: 16),
          Text('Hapus Kategori?',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Kategori "${category.name}" akan dihapus permanen.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: c.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
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
                              color: c.textSecondary)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final provider = context.read<FinanceProvider>();
                    final isUsed = provider.transactions
                        .any((t) => t.categoryId == category.id);
                    
                    if (isUsed) {
                      Navigator.pop(context);
                      AppToast.error(
                          context, 'Kategori masih digunakan di transaksi');
                      return;
                    }
                    
                    provider.deleteCategory(category.id);
                    Navigator.pop(context); // Close confirm sheet
                    Navigator.pop(context); // Close edit sheet (since it's called from there)
                    AppToast.success(context, 'Kategori berhasil dihapus');
                    onDeleted();
                  },
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
                              color: c.cardBg)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
