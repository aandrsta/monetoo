// lib/screens/category_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/finance_provider.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/add_transaction_bottom_sheet.dart';

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

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, provider, _) {
            // Calculate monthly totals
            final monthlyTransactions = provider.transactions.where((t) {
              return t.date.year == _selectedMonth.year &&
                  t.date.month == _selectedMonth.month;
            }).toList();

            final monthlyIncome = monthlyTransactions
                .where((t) => t.type == TransactionType.income)
                .fold(0.0, (sum, t) => sum + t.amount);

            final monthlyExpense = monthlyTransactions
                .where((t) => t.type == TransactionType.expense)
                .fold(0.0, (sum, t) => sum + t.amount);

            final monthlyBalance = monthlyIncome - monthlyExpense;

            return Column(
              children: [
                // Header with balance
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    children: [
                      Text(
                        'Saldo keseluruhan',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(monthlyBalance),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: monthlyBalance >= 0
                              ? AppTheme.textPrimary
                              : AppTheme.expense,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Month selector - simple style like transaction screen
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => _changeMonth(-1),
                            icon: const Icon(Icons.chevron_left_rounded,
                                color: AppTheme.textPrimary),
                          ),
                          Text(
                            DateFormatter.formatMonthYear(_selectedMonth),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          IconButton(
                            onPressed: _selectedMonth.month ==
                                        DateTime.now().month &&
                                    _selectedMonth.year == DateTime.now().year
                                ? null
                                : () => _changeMonth(1),
                            icon: Icon(
                              Icons.chevron_right_rounded,
                              color: _selectedMonth.month ==
                                          DateTime.now().month &&
                                      _selectedMonth.year == DateTime.now().year
                                  ? AppTheme.divider
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Income/Expense summary - now clickable
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedType = TransactionType.expense;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        _selectedType == TransactionType.expense
                                            ? AppTheme.expense
                                            : Colors.grey.shade200,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
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
                                            ? AppTheme.expense
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(monthlyExpense),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.expense,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedType = TransactionType.income;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        _selectedType == TransactionType.income
                                            ? AppTheme.income
                                            : Colors.grey.shade200,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pendapatan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _selectedType ==
                                                TransactionType.income
                                            ? AppTheme.income
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(monthlyIncome),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.income,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Category grid
                Expanded(
                  child: _buildCategoryGrid(
                    provider,
                    monthlyTransactions,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(
    FinanceProvider provider,
    List<TransactionModel> monthlyTransactions,
  ) {
    // Calculate category stats for the selected month
    final Map<String, Map<String, dynamic>> categoryStats = {};

    for (final t in monthlyTransactions) {
      if (!categoryStats.containsKey(t.categoryName)) {
        categoryStats[t.categoryName] = {
          'amount': 0.0,
          'count': 0,
          'type': t.type,
        };
      }
      categoryStats[t.categoryName]!['amount'] += t.amount;
      categoryStats[t.categoryName]!['count'] += 1;
    }

    // Filter categories based on selected type
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
      itemCount: categories.length + 1, // +1 for add button
      itemBuilder: (context, index) {
        if (index == categories.length) {
          return _buildAddCategoryButton();
        }

        final cat = categories[index];
        final stats = categoryStats[cat.name] ??
            {'amount': 0.0, 'count': 0, 'type': cat.type};
        return _buildCategoryCard(cat, stats, provider, monthlyTransactions);
      },
    );
  }

  Widget _buildAddCategoryButton() {
    return GestureDetector(
      onTap: () => _showAddCategorySheet(context, _selectedType),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accent.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppTheme.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tambah Kategori',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    CategoryModel category,
    Map<String, dynamic> stats,
    FinanceProvider provider,
    List<TransactionModel> monthlyTransactions,
  ) {
    final amount = stats['amount'] ?? 0.0;

    return GestureDetector(
      onTap: () {
        // Open bottom sheet to add transaction with this category
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddTransactionBottomSheet(initialCategory: category),
        );
      },
      onLongPress: () {
        // Open edit category sheet
        _showCategorySheet(context, category, category.type);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(category.color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  category.icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatCompact(amount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: category.type == TransactionType.expense
                          ? AppTheme.expense
                          : AppTheme.income,
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

  void _showAddCategorySheet(BuildContext context, TransactionType type) {
    _showCategorySheet(context, null, type);
  }

  void _showCategorySheet(BuildContext context, CategoryModel? existing,
      TransactionType defaultType) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    String selectedIcon = existing?.icon ?? '📦';
    int selectedColor = existing?.color ?? 0xFF7C6FFF;
    TransactionType selectedType = existing?.type ?? defaultType;

    final icons = [
      '🍜',
      '🍕',
      '☕',
      '🍔',
      '🍰',
      '🍱',
      '🍗',
      '🥗',
      '🍛',
      '🍝',
      '🚗',
      '🚌',
      '✈️',
      '🚕',
      '🏍️',
      '🚲',
      '🚇',
      '⛴️',
      '🛍️',
      '👗',
      '👕',
      '👟',
      '🎽',
      '👜',
      '💡',
      '📱',
      '💻',
      '⌚',
      '📷',
      '🖨️',
      '🏥',
      '💊',
      '💉',
      '🏨',
      '🎮',
      '🎬',
      '🎵',
      '🎸',
      '🎤',
      '🎧',
      '📚',
      '📝',
      '✏️',
      '📖',
      '🏋️',
      '⚽',
      '🏀',
      '🎾',
      '⛽',
      '🏠',
      '🏢',
      '🏦',
      '💼',
      '📈',
      '📊',
      '💹',
      '🎁',
      '💰',
      '💳',
      '💵',
      '💸',
      '🏧',
      '🔧',
      '🔨',
      '🛠️',
      '🌿',
      '🌺',
      '🌸',
      '🐾',
      '🐕',
      '🐈',
      '📦',
      '✨',
      '⭐',
      '🎯',
      '❤️',
      '🔥',
      '🎨',
      '📅',
      '🍎',
      '🥤',
      '🍿',
    ];

    final colors = [
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  existing == null ? 'Tambah Kategori' : 'Edit Kategori',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type selector
                      if (existing == null) ...[
                        Text('Tipe',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _typeChip(
                                'Pengeluaran',
                                TransactionType.expense,
                                selectedType,
                                AppTheme.expense,
                                (t) => setModalState(() => selectedType = t),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _typeChip(
                                'Pemasukan',
                                TransactionType.income,
                                selectedType,
                                AppTheme.income,
                                (t) => setModalState(() => selectedType = t),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Name
                      Text('Nama Kategori',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Kuliner, Transport...',
                          prefixIcon: Text(
                            selectedIcon,
                            style: const TextStyle(fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 48, maxWidth: 48),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Randomize button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final random = Random();
                            setModalState(() {
                              selectedIcon =
                                  icons[random.nextInt(icons.length)];
                              selectedColor =
                                  colors[random.nextInt(colors.length)];
                            });
                          },
                          icon: const Icon(Icons.shuffle_rounded),
                          label: const Text('Acak Ikon & Warna'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accent,
                            side: const BorderSide(color: AppTheme.accent),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Icon picker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pilih Ikon',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${icons.length} ikon',
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount:
                            18, // 3 rows x 6 columns = 18 (17 icons + 1 more button)
                        itemBuilder: (_, i) {
                          // Last item is "More Icon" button
                          if (i == 17) {
                            return GestureDetector(
                              onTap: () async {
                                final result = await showDialog<String>(
                                  context: context,
                                  builder: (dialogCtx) =>
                                      _buildIconPickerDialog(
                                    icons,
                                    selectedIcon,
                                    selectedColor,
                                  ),
                                );
                                if (result != null) {
                                  setModalState(() => selectedIcon = result);
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppTheme.accent.withOpacity(0.3),
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: AppTheme.accent,
                                    size: 24,
                                  ),
                                ),
                              ),
                            );
                          }

                          return GestureDetector(
                            onTap: () =>
                                setModalState(() => selectedIcon = icons[i]),
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedIcon == icons[i]
                                    ? Color(selectedColor).withOpacity(0.15)
                                    : AppTheme.bgLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedIcon == icons[i]
                                      ? Color(selectedColor)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(icons[i],
                                    style: const TextStyle(fontSize: 22)),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Color picker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pilih Warna',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${colors.length} warna',
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary)),
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
                        itemCount: colors.length,
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedColor = colors[i]),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(colors[i]),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == colors[i]
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: selectedColor == colors[i]
                                  ? [
                                      BoxShadow(
                                          color:
                                              Color(colors[i]).withOpacity(0.5),
                                          blurRadius: 8)
                                    ]
                                  : [],
                            ),
                            child: selectedColor == colors[i]
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Delete button (for all existing categories)
                      if (existing != null) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Check if category is being used
                              final provider = context.read<FinanceProvider>();
                              final isUsed = provider.transactions
                                  .any((t) => t.categoryName == existing.name);

                              if (isUsed) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Tidak bisa hapus kategori yang masih digunakan'),
                                    backgroundColor: AppTheme.expense,
                                  ),
                                );
                                return;
                              }

                              // Show confirmation dialog
                              showDialog(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  title: const Text('Hapus Kategori?'),
                                  content: Text(
                                      'Kategori "${existing.name}" akan dihapus permanen'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogCtx),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        provider.deleteCategory(existing.id);
                                        Navigator.pop(
                                            dialogCtx); // Close dialog
                                        Navigator.pop(ctx); // Close sheet
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Kategori berhasil dihapus'),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.expense,
                                      ),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Hapus Kategori'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.expense,
                              side: const BorderSide(color: AppTheme.expense),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (nameController.text.isEmpty) return;
                            final provider = context.read<FinanceProvider>();
                            final category = CategoryModel(
                              id: existing?.id ?? const Uuid().v4(),
                              name: nameController.text.trim(),
                              icon: selectedIcon,
                              color: selectedColor,
                              type: existing?.type ?? selectedType,
                              isDefault: existing?.isDefault ?? false,
                              createdAt: existing?.createdAt ?? DateTime.now(),
                            );

                            if (existing == null) {
                              provider.addCategory(category);
                            } else {
                              provider.updateCategory(category);
                            }
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(selectedColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            existing == null
                                ? 'Tambah Kategori'
                                : 'Simpan Perubahan',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(
    String label,
    TransactionType type,
    TransactionType selected,
    Color color,
    Function(TransactionType) onTap,
  ) {
    final isSelected = type == selected;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.bgLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconPickerDialog(
    List<String> icons,
    String selectedIcon,
    int selectedColor,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Ikon',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${icons.length} ikon',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Icon grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: icons.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => Navigator.pop(context, icons[i]),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selectedIcon == icons[i]
                          ? Color(selectedColor).withOpacity(0.15)
                          : AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedIcon == icons[i]
                            ? Color(selectedColor)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        icons[i],
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
