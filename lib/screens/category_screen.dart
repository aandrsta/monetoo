import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_colors.dart';
import '../utils/currency_formatter.dart';
import '../widgets/add_transaction_bottom_sheet.dart';
import '../utils/icon_data.dart';
import '../widgets/category_edit_sheet.dart';
import '../widgets/confirm_delete_category_sheet.dart';


class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  TransactionType _selectedType = TransactionType.expense;

  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, provider, _) {
            final monthlyTx = provider.transactions
                .where((t) =>
                    t.date.year == _selectedMonth.year &&
                    t.date.month == _selectedMonth.month)
                .toList();

            final monthlyIncome = monthlyTx.totalIncome;
            final monthlyExpense = monthlyTx.totalExpense;
            final monthlyBalance = monthlyTx.balance;

            return Column(
              children: [
                // ── HEADER ──
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Saldo keseluruhan',
                                  style: TextStyle(
                                      fontSize: 14, color: c.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(monthlyBalance),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: monthlyBalance >= 0
                                      ? c.textPrimary
                                      : c.expense,
                                ),
                              ),
                            ],
                          ),
                          EditModeButton(
                            isEditMode: _editMode,
                            onTap: () {
                              setState(() => _editMode = !_editMode);
                              if (_editMode) {
                                AppToast.info(context, 'Ketuk kategori untuk edit');
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      MonthSelectorBar(
                        selectedMonth: _selectedMonth,
                        onChanged: (date) => setState(() => _selectedMonth = date),
                      ),
                      const SizedBox(height: 16),

                      // Income/Expense selector
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() =>
                                  _selectedType = TransactionType.expense),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: c.cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        _selectedType == TransactionType.expense
                                            ? c.expense
                                            : Colors.grey.shade200,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2))
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pengeluaran',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: _selectedType ==
                                                  TransactionType.expense
                                              ? c.expense
                                              : c.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(monthlyExpense),
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: c.expense),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _selectedType = TransactionType.income),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: c.cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        _selectedType == TransactionType.income
                                            ? c.income
                                            : Colors.grey.shade200,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2))
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pemasukan',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: _selectedType ==
                                                  TransactionType.income
                                              ? c.income
                                              : c.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(monthlyIncome),
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: c.income),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_editMode) ...[
                        const SizedBox(height: 12),
                        const EditModeBanner(
                          message: 'Mode edit aktif — ketuk kategori untuk ubah atau hapus',
                        ),
                      ],
                    ],
                  ),
                ),

                Expanded(
                  child: _buildCategoryGrid(provider, monthlyTx),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(
      FinanceProvider provider, List<TransactionModel> monthlyTx) {
    // final c = context.colors;
    final Map<String, Map<String, dynamic>> stats = {};
    for (final t in monthlyTx) {
      stats[t.categoryName] ??= {'amount': 0.0, 'count': 0, 'type': t.type};
      stats[t.categoryName]!['amount'] += t.amount;
      stats[t.categoryName]!['count'] += 1;
    }

    final categories = _selectedType == TransactionType.expense
        ? provider.expenseCategories
        : provider.incomeCategories;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: categories.length + 1,
      itemBuilder: (context, index) {
        if (index == categories.length) {
          return _buildAddCategoryButton();
        }
        final cat = categories[index];
        final stat =
            stats[cat.name] ?? {'amount': 0.0, 'count': 0, 'type': cat.type};
        return _buildCategoryCard(cat, stat, provider);
      },
    );
  }

  Widget _buildCategoryCard(
    CategoryModel category,
    Map<String, dynamic> stats,
    FinanceProvider provider,
  ) {
    final c = context.colors;
    final amount = stats['amount'] ?? 0.0;
    final isEditMode = _editMode;

    return GestureDetector(
      onTap: () {
        if (isEditMode) {
          CategoryEditSheet.show(
            context,
            existing: category,
            defaultType: category.type,
            onSaved: () => setState(() => _editMode = false),
          );
        } else {
          AddTransactionBottomSheet.show(context, initialCategory: category);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEditMode
              ? Color(category.color).withValues(alpha: 0.08)
              : c.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEditMode
                ? Color(category.color).withValues(alpha: 0.4)
                : Colors.transparent,
            width: isEditMode ? 1.5 : 0,
          ),
          boxShadow: isEditMode
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(category.color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(category.icon, style: TextStyle(fontSize: 22)),
                  ),
                ),
                if (isEditMode)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.cardBg, width: 1.5),
                      ),
                      child: Icon(Icons.edit_rounded, size: 8, color: c.cardBg),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEditMode
                        ? 'Ketuk untuk edit'
                        : CurrencyFormatter.formatCompact(amount),
                    style: TextStyle(
                      fontSize: isEditMode ? 11 : 14,
                      fontWeight:
                          isEditMode ? FontWeight.w400 : FontWeight.w700,
                      color: isEditMode
                          ? c.textSecondary
                          : category.type == TransactionType.expense
                              ? c.expense
                              : c.income,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryButton() {
    final c = context.colors;
    return GestureDetector(
      onTap: () {
        if (_editMode) setState(() => _editMode = false);
        CategoryEditSheet.show(
          context,
          defaultType: _selectedType,
          onSaved: () {},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.accent.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.add_rounded, color: c.accent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Tambah kategori',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.accent)),
            ),
          ],
        ),
      ),
    );
  }
}

