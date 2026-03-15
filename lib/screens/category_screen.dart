// lib/screens/category_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/finance_provider.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../utils/app_theme.dart';
import '../utils/app_toast.dart';
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

  // Mode edit — toggle dengan tombol pensil
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
            final monthlyTx = provider.transactions
                .where((t) =>
                    t.date.year == _selectedMonth.year &&
                    t.date.month == _selectedMonth.month)
                .toList();

            final monthlyIncome = monthlyTx
                .where((t) => t.type == TransactionType.income)
                .fold(0.0, (s, t) => s + t.amount);
            final monthlyExpense = monthlyTx
                .where((t) => t.type == TransactionType.expense)
                .fold(0.0, (s, t) => s + t.amount);
            final monthlyBalance = monthlyIncome - monthlyExpense;

            return Column(
              children: [
                // ── HEADER ──
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    children: [
                      // Title row dengan tombol pensil
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Saldo keseluruhan',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary)),
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
                            ],
                          ),
                          // Tombol pensil — toggle edit mode
                          GestureDetector(
                            onTap: () {
                              setState(() => _editMode = !_editMode);
                              if (_editMode) {
                                AppToast.info(
                                    context, 'Ketuk kategori untuk edit');
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _editMode
                                    ? AppTheme.accent
                                    : AppTheme.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _editMode
                                    ? Icons.edit_rounded
                                    : Icons.edit_outlined,
                                color:
                                    _editMode ? Colors.white : AppTheme.accent,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Month selector
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
                                color: AppTheme.textPrimary),
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
                                              ? AppTheme.expense
                                              : AppTheme.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(monthlyExpense),
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.expense),
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
                                      'Pendapatan',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: _selectedType ==
                                                  TransactionType.income
                                              ? AppTheme.income
                                              : AppTheme.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(monthlyIncome),
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.income),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Banner edit mode
                      if (_editMode) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.accent.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 16,
                                  color:
                                      AppTheme.accent.withValues(alpha: 0.8)),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Mode edit aktif — ketuk kategori untuk ubah atau hapus',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── GRID KATEGORI ──
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
    final amount = stats['amount'] ?? 0.0;
    final isEditMode = _editMode;

    return GestureDetector(
      onTap: () {
        if (isEditMode) {
          // Edit mode: buka sheet edit langsung
          _showCategorySheet(context, category, category.type);
        } else {
          // Normal mode: buka tambah transaksi
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) =>
                AddTransactionBottomSheet(initialCategory: category),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEditMode
              ? Color(category.color).withValues(alpha: 0.08)
              : Colors.white,
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
                    child: Text(category.icon,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                // Badge pensil kecil di pojok saat edit mode
                if (isEditMode)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          size: 8, color: Colors.white),
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
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
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
                          ? AppTheme.textSecondary
                          : category.type == TransactionType.expense
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

  Widget _buildAddCategoryButton() {
    return GestureDetector(
      onTap: () {
        // Saat tambah, nonaktifkan edit mode dulu
        if (_editMode) setState(() => _editMode = false);
        _showCategorySheet(context, null, _selectedType);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.accent.withValues(alpha: 0.3), width: 2),
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
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_rounded,
                  color: AppTheme.accent, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Tambah kategori',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent)),
            ),
          ],
        ),
      ),
    );
  }

  // ── CATEGORY SHEET ──

  void _showCategorySheet(BuildContext context, CategoryModel? existing,
      TransactionType defaultType) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
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
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  existing == null ? 'Tambah kategori' : 'Edit kategori',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipe (hanya saat tambah baru)
                      if (existing == null) ...[
                        const Text('Tipe',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: _catTypeChip(
                              'Pengeluaran',
                              TransactionType.expense,
                              selectedType,
                              AppTheme.expense,
                              (t) => setModal(() => selectedType = t),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _catTypeChip(
                              'Pemasukan',
                              TransactionType.income,
                              selectedType,
                              AppTheme.income,
                              (t) => setModal(() => selectedType = t),
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
                        controller: nameCtrl,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Kuliner, Transport...',
                          prefixIcon: Text(selectedIcon,
                              style: const TextStyle(fontSize: 20),
                              textAlign: TextAlign.center),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 48, maxWidth: 48),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Acak
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final rng = Random();
                            setModal(() {
                              selectedIcon = icons[rng.nextInt(icons.length)];
                              selectedColor =
                                  colors[rng.nextInt(colors.length)];
                            });
                          },
                          icon: const Icon(Icons.shuffle_rounded),
                          label: const Text('Acak Ikon & Warna'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accent,
                            side: const BorderSide(color: AppTheme.accent),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Icon picker (3 baris pertama + tombol lihat semua)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pilih Ikon',
                              style: TextStyle(
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
                        itemCount: 18,
                        itemBuilder: (_, i) {
                          if (i == 17) {
                            return GestureDetector(
                              onTap: () async {
                                final result = await showDialog<String>(
                                  context: context,
                                  builder: (_) => _IconPickerDialog(
                                    icons: icons,
                                    selectedIcon: selectedIcon,
                                    selectedColor: selectedColor,
                                  ),
                                );
                                if (result != null) {
                                  setModal(() => selectedIcon = result);
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppTheme.accent
                                          .withValues(alpha: 0.3),
                                      width: 2),
                                ),
                                child: const Center(
                                    child: Icon(Icons.add_rounded,
                                        color: AppTheme.accent, size: 24)),
                              ),
                            );
                          }
                          return GestureDetector(
                            onTap: () =>
                                setModal(() => selectedIcon = icons[i]),
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedIcon == icons[i]
                                    ? Color(selectedColor)
                                        .withValues(alpha: 0.15)
                                    : AppTheme.bgLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: selectedIcon == icons[i]
                                        ? Color(selectedColor)
                                        : Colors.transparent,
                                    width: 2),
                              ),
                              child: Center(
                                  child: Text(icons[i],
                                      style: const TextStyle(fontSize: 22))),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Color picker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pilih Warna',
                              style: TextStyle(
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
                              setModal(() => selectedColor = colors[i]),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(colors[i]),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: selectedColor == colors[i]
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2),
                              boxShadow: selectedColor == colors[i]
                                  ? [
                                      BoxShadow(
                                          color: Color(colors[i])
                                              .withValues(alpha: 0.5),
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

                      // Hapus (hanya saat edit)
                      if (existing != null) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _confirmDeleteCategory(ctx, existing),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Hapus Kategori'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.expense,
                              side: const BorderSide(color: AppTheme.expense),
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
                            if (nameCtrl.text.trim().isEmpty) {
                              AppToast.error(
                                  context, 'Nama kategori tidak boleh kosong');
                              return;
                            }
                            final provider = context.read<FinanceProvider>();
                            final category = CategoryModel(
                              id: existing?.id ?? const Uuid().v4(),
                              name: nameCtrl.text.trim(),
                              icon: selectedIcon,
                              color: selectedColor,
                              type: existing?.type ?? selectedType,
                              isDefault: existing?.isDefault ?? false,
                              createdAt: existing?.createdAt ?? DateTime.now(),
                            );
                            if (existing == null) {
                              provider.addCategory(category);
                              Navigator.pop(ctx);
                              AppToast.success(
                                  context, 'Kategori berhasil ditambahkan');
                            } else {
                              provider.updateCategory(category);
                              Navigator.pop(ctx);
                              AppToast.success(
                                  context, 'Kategori berhasil diperbarui');
                              // Matikan edit mode setelah edit
                              setState(() => _editMode = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(selectedColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            existing == null
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
        ),
      ),
    );
  }

  // ── CONFIRM DELETE CATEGORY ──

  void _confirmDeleteCategory(BuildContext sheetCtx, CategoryModel category) {
    showModalBottomSheet(
      context: sheetCtx,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.expense.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.expense, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Hapus Kategori?',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Kategori "${category.name}" akan dihapus permanen.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: AppTheme.bgLight,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                        child: Text('Batal',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary)),
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
                          .any((t) => t.categoryName == category.name);
                      if (isUsed) {
                        Navigator.pop(ctx);
                        AppToast.error(
                            context, 'Kategori masih digunakan di transaksi');
                        return;
                      }
                      provider.deleteCategory(category.id);
                      Navigator.pop(ctx); // tutup confirm
                      Navigator.pop(sheetCtx); // tutup edit sheet
                      AppToast.success(context, 'Kategori berhasil dihapus');
                      setState(() => _editMode = false);
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: AppTheme.expense,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                        child: Text('Hapus',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    final isSel = type == selected;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? color : AppTheme.bgLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSel ? Colors.white : AppTheme.textSecondary)),
        ),
      ),
    );
  }
}

// ── ICON PICKER DIALOG ──

class _IconPickerDialog extends StatelessWidget {
  final List<String> icons;
  final String selectedIcon;
  final int selectedColor;

  const _IconPickerDialog({
    required this.icons,
    required this.selectedIcon,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.maxFinite,
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pilih Ikon',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text('${icons.length} ikon',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Divider(height: 1),
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
                          ? Color(selectedColor).withValues(alpha: 0.15)
                          : AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selectedIcon == icons[i]
                              ? Color(selectedColor)
                              : Colors.transparent,
                          width: 2),
                    ),
                    child: Center(
                        child: Text(icons[i],
                            style: const TextStyle(fontSize: 22))),
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
