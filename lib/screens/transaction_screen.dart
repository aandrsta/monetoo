// lib/screens/transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_colors.dart';
import '../utils/currency_formatter.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/add_transaction_bottom_sheet.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String _filter = 'all';
  DateTime _selectedMonth = DateTime.now();

  Future<void> _pickMonth(BuildContext context) async {
    final c = context.colors;
    int pickedYear = _selectedMonth.year;
    int pickedMonth = _selectedMonth.month;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: c.modalBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Pilih Bulan',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => setD(() => pickedYear--),
                      icon: Icon(Icons.chevron_left_rounded,
                          color: c.textPrimary),
                    ),
                    Text('$pickedYear',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary)),
                    IconButton(
                      onPressed: () => setD(() => pickedYear++),
                      icon: Icon(Icons.chevron_right_rounded,
                          color: c.textPrimary),
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
                    final isSelected = m == pickedMonth;
                    final monthName = [
                      'Jan',
                      'Feb',
                      'Mar',
                      'Apr',
                      'Mei',
                      'Jun',
                      'Jul',
                      'Agu',
                      'Sep',
                      'Okt',
                      'Nov',
                      'Des'
                    ][i];
                    return GestureDetector(
                      onTap: () => setD(() => pickedMonth = m),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? c.accent : c.bgLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(monthName,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isSelected ? c.cardBg : c.textSecondary)),
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
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: TextStyle(color: c.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(pickedYear, pickedMonth);
                });
                Navigator.pop(ctx);
              },
              child: Text('Pilih', style: TextStyle(color: c.accent)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddTransactionBottomSheet(),
            );
          },
          icon: Icon(Icons.add_rounded),
          label: Text('Tambah'),
          backgroundColor: c.accent,
          foregroundColor: c.cardBg,
          elevation: 0,
          highlightElevation: 0,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text('Transaksi',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary)),
                    ],
                  ),
                ),
                _buildMonthSelector(context),
                _buildFilterChips(),
                FutureBuilder<List<TransactionModel>>(
                  future: provider.getTransactionsByMonth(
                      _selectedMonth.year, _selectedMonth.month),
                  builder: (context, snapshot) {
                    final all = snapshot.data ?? [];
                    final filtered = _applyFilter(all);
                    final income = all
                        .where((t) => t.type == TransactionType.income)
                        .fold(0.0, (s, t) => s + t.amount);
                    final expense = all
                        .where((t) => t.type == TransactionType.expense)
                        .fold(0.0, (s, t) => s + t.amount);

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

  Widget _buildMonthSelector(BuildContext context) {
    final c = context.colors;
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
            icon: Icon(Icons.chevron_left_rounded, color: c.textPrimary),
          ),
          GestureDetector(
            onTap: () => _pickMonth(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormatter.formatMonthYear(_selectedMonth),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: c.textSecondary),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              _selectedMonth =
                  DateTime(_selectedMonth.year, _selectedMonth.month + 1);
            }),
            icon: Icon(Icons.chevron_right_rounded, color: c.textPrimary),
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
    final c = context.colors;
    final isSelected = _filter == value;
    Color color = c.accent;
    if (value == 'income') color = c.income;
    if (value == 'expense') color = c.expense;

    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : c.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : c.divider),
          boxShadow: isSelected ? [] : c.cardShadow,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? c.cardBg : color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? c.cardBg : c.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummary(double income, double expense) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                  color: c.incomeLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Masuk',
                      style: TextStyle(fontSize: 11, color: c.income)),
                  Text(CurrencyFormatter.formatCompact(income),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.income)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                  color: c.expenseLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Keluar',
                      style: TextStyle(fontSize: 11, color: c.expense)),
                  Text(CurrencyFormatter.formatCompact(expense),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.expense)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                  color: c.bgLight, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saldo',
                      style: TextStyle(fontSize: 11, color: c.accent)),
                  Text(CurrencyFormatter.formatCompact(income - expense),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.accent)),
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
    final c = context.colors;
    final Map<String, List<TransactionModel>> groups = {};
    for (final t in transactions) {
      final key =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      groups[key] ??= [];
      groups[key]!.add(t);
    }

    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary),
                  ),
                  Row(
                    children: [
                      if (dayIncome > 0)
                        Text('+${CurrencyFormatter.formatCompact(dayIncome)}',
                            style: TextStyle(
                                fontSize: 12,
                                color: c.income,
                                fontWeight: FontWeight.w500)),
                      if (dayIncome > 0 && dayExpense > 0)
                        const SizedBox(width: 8),
                      if (dayExpense > 0)
                        Text('-${CurrencyFormatter.formatCompact(dayExpense)}',
                            style: TextStyle(
                                fontSize: 12,
                                color: c.expense,
                                fontWeight: FontWeight.w500)),
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
                      builder: (_) => AddTransactionBottomSheet(transaction: t),
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildEmpty() {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 64, color: c.divider),
          const SizedBox(height: 16),
          Text('Tidak ada transaksi',
              style: TextStyle(fontSize: 15, color: c.textSecondary)),
        ],
      ),
    );
  }
}
