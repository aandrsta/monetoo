// lib/widgets/transaction/category_picker.dart

import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../utils/app_colors.dart';

class CategoryPicker extends StatelessWidget {
  final List<CategoryModel> categories;
  final CategoryModel? selectedCategory;
  final TransactionType type;
  final Function(CategoryModel) onSelected;

  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.type,
    required this.onSelected,
  });

  static void show(
    BuildContext context, {
    required List<CategoryModel> categories,
    required CategoryModel? selectedCategory,
    required TransactionType type,
    required Function(CategoryModel) onSelected,
  }) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: c.modalBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: c.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(
              type == TransactionType.expense
                  ? 'Kategori Pengeluaran'
                  : 'Kategori Pemasukan',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: categories.length,
                itemBuilder: (ctx, i) {
                  final cat = categories[i];
                  final isSel = selectedCategory?.id == cat.id;
                  return GestureDetector(
                    onTap: () {
                      onSelected(cat);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(cat.color).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color:
                                isSel ? Color(cat.color) : Colors.transparent,
                            width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat.icon, style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(cat.name,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget is primarily used via its static show method, 
    // but we could use it as a standalone widget if needed.
    return const SizedBox.shrink();
  }
}
