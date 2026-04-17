// lib/screens/transaction_screen.dart

import '../utils/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_colors.dart';
import '../utils/currency_formatter.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/add_transaction_bottom_sheet.dart';
import '../widgets/month_selector_bar.dart';
import '../widgets/transaction_filter_chips.dart';
import '../widgets/income_expense_summary.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String _filter = 'all';
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: () => AddTransactionBottomSheet.show(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah'),
          backgroundColor: c.accent,
          foregroundColor: c.cardBg,
          elevation: 4,
          highlightElevation: 8,
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
                MonthSelectorBar(
                  selectedMonth: _selectedMonth,
                  onChanged: (date) => setState(() => _selectedMonth = date),
                ),
                TransactionFilterChips(
                  selectedFilter: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
                Builder(
                  builder: (context) {
                    final all = provider.transactions
                        .where((t) =>
                            t.date.year == _selectedMonth.year &&
                            t.date.month == _selectedMonth.month)
                        .toList();
                    final filtered = _applyFilter(all);

                    final openingBalance = provider.getOpeningBalanceForMonth(
                        _selectedMonth.year, _selectedMonth.month);
                    final currentBalance =
                        openingBalance + all.totalIncome - all.totalExpense;

                    return Expanded(
                      child: Column(
                        children: [
                          IncomeExpenseSummary(
                            income: all.totalIncome,
                            expense: all.totalExpense,
                            balance: currentBalance,
                          ),
                          if (filtered.isEmpty)
                            Expanded(child: _buildEmpty())
                          else
                            Expanded(
                              child: _buildGroupedList(filtered, provider),
                            ),
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

  Widget _buildGroupedList(
      List<TransactionModel> transactions, FinanceProvider provider) {
    final c = context.colors;
    final groups = transactions.groupByDate();
    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final dayTransactions = groups[key]!;
        final date = dayTransactions.first.date;
        final dayIncome = dayTransactions.totalIncome;
        final dayExpense = dayTransactions.totalExpense;

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
                    onDelete: () {
                      provider.deleteTransaction(t.id);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          AppToast.success(context, 'Transaksi berhasil dihapus');
                        }
                      });
                    },
                    onEdit: () =>
                        AddTransactionBottomSheet.show(context, transaction: t),
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
