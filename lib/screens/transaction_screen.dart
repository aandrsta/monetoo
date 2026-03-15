// lib/screens/transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/add_transaction_bottom_sheet.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String _filter = 'all'; // all, income, expense
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddTransactionBottomSheet(),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                // Header
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transaksi',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Month selector
                _buildMonthSelector(),
                // Filter chips
                _buildFilterChips(),
                // Summary bar
                FutureBuilder<List<TransactionModel>>(
                  future: provider.getTransactionsByMonth(
                      _selectedMonth.year, _selectedMonth.month),
                  builder: (context, snapshot) {
                    final all = snapshot.data ?? [];
                    final filtered = _applyFilter(all);
                    final income = all
                        .where((t) => t.type == TransactionType.income)
                        .fold(0.0, (sum, t) => sum + t.amount);
                    final expense = all
                        .where((t) => t.type == TransactionType.expense)
                        .fold(0.0, (sum, t) => sum + t.amount);

                    return Expanded(
                      child: Column(
                        children: [
                          _buildMonthlySummary(income, expense),
                          if (filtered.isEmpty)
                            Expanded(child: _buildEmpty())
                          else
                            Expanded(
                              child: _buildGroupedList(filtered, provider),
                            ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<TransactionModel> _applyFilter(List<TransactionModel> list) {
    if (_filter == 'income') {
      return list.where((t) => t.type == TransactionType.income).toList();
    }
    if (_filter == 'expense') {
      return list.where((t) => t.type == TransactionType.expense).toList();
    }
    return list;
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => setState(() {
              _selectedMonth =
                  DateTime(_selectedMonth.year, _selectedMonth.month - 1);
            }),
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
            onPressed: _selectedMonth.month == DateTime.now().month &&
                    _selectedMonth.year == DateTime.now().year
                ? null
                : () => setState(() {
                      _selectedMonth = DateTime(
                          _selectedMonth.year, _selectedMonth.month + 1);
                    }),
            icon: Icon(
              Icons.chevron_right_rounded,
              color: _selectedMonth.month == DateTime.now().month &&
                      _selectedMonth.year == DateTime.now().year
                  ? AppTheme.divider
                  : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _filterChip('all', 'Semua', Icons.list_rounded),
          const SizedBox(width: 8),
          _filterChip('income', 'Pemasukan', Icons.arrow_downward_rounded),
          const SizedBox(width: 8),
          _filterChip('expense', 'Pengeluaran', Icons.arrow_upward_rounded),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label, IconData icon) {
    final isSelected = _filter == value;
    Color color = AppTheme.accent;
    if (value == 'income') color = AppTheme.income;
    if (value == 'expense') color = AppTheme.expense;

    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : AppTheme.divider),
          boxShadow: isSelected ? [] : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummary(double income, double expense) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.incomeLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Masuk',
                      style: TextStyle(fontSize: 11, color: AppTheme.income)),
                  Text(
                    CurrencyFormatter.formatCompact(income),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.income,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.expenseLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Keluar',
                      style: TextStyle(fontSize: 11, color: AppTheme.expense)),
                  Text(
                    CurrencyFormatter.formatCompact(expense),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.expense,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saldo',
                      style: TextStyle(fontSize: 11, color: AppTheme.accent)),
                  Text(
                    CurrencyFormatter.formatCompact(income - expense),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent,
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

  Widget _buildGroupedList(
      List<TransactionModel> transactions, FinanceProvider provider) {
    // Group by date
    final Map<String, List<TransactionModel>> groups = {};
    for (final t in transactions) {
      final key = '${t.date.year}-${t.date.month}-${t.date.day}';
      groups[key] ??= [];
      groups[key]!.add(t);
    }

    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final dayTransactions = groups[key]!;
        final date = dayTransactions.first.date;
        final dayIncome = dayTransactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount);
        final dayExpense = dayTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatter.isSameDay(date, DateTime.now())
                        ? 'Hari ini'
                        : DateFormatter.formatShort(date),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      if (dayIncome > 0)
                        Text(
                          '+${CurrencyFormatter.formatCompact(dayIncome)}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.income,
                              fontWeight: FontWeight.w500),
                        ),
                      if (dayIncome > 0 && dayExpense > 0)
                        const SizedBox(width: 8),
                      if (dayExpense > 0)
                        Text(
                          '-${CurrencyFormatter.formatCompact(dayExpense)}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.expense,
                              fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            ...dayTransactions.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TransactionTile(
                    transaction: t,
                    onDelete: () => provider.deleteTransaction(t.id),
                    onEdit: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AddTransactionBottomSheet(
                        transaction: t,
                      ),
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 64, color: AppTheme.divider),
          SizedBox(height: 16),
          Text(
            'Tidak ada transaksi',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
