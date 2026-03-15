// lib/screens/statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/add_transaction_bottom_sheet.dart';
import '../widgets/transaction_tile.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime _selectedMonth = DateTime.now();
  int _touchedCategoryIndex = -1;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, provider, _) {
            final monthTransactions = provider.transactions
                .where((transaction) =>
                    transaction.date.year == _selectedMonth.year &&
                    transaction.date.month == _selectedMonth.month)
                .toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),
                SliverToBoxAdapter(
                  child: _buildMonthSelector(),
                ),
                SliverToBoxAdapter(
                  child: _buildMonthlyOverview(monthTransactions),
                ),
                SliverToBoxAdapter(
                  child: _buildDailyIncomeExpenseChart(monthTransactions),
                ),
                SliverToBoxAdapter(
                  child:
                      _buildMonthlyCategoryChart(provider, monthTransactions),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik Keuangan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Pantau pengeluaran dan pemasukan Anda',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
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
            onPressed: _isCurrentMonth ? null : () => _changeMonth(1),
            icon: Icon(
              Icons.chevron_right_rounded,
              color: _isCurrentMonth ? AppTheme.divider : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyOverview(List<TransactionModel> monthTransactions) {
    final income = monthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expense = monthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final balance = income - expense;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Bulanan',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormatter.formatMonthYear(_selectedMonth),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pemasukan',
                    income,
                    Icons.arrow_downward_rounded,
                    AppTheme.income,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pengeluaran',
                    expense,
                    Icons.arrow_upward_rounded,
                    AppTheme.expense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saldo Akhir',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(balance),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: balance >= 0 ? AppTheme.income : AppTheme.expense,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyIncomeExpenseChart(
      List<TransactionModel> monthTransactions) {
    final totalDays =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final dailyIncome = List<double>.filled(totalDays, 0);
    final dailyExpense = List<double>.filled(totalDays, 0);

    for (final transaction in monthTransactions) {
      final dayIndex = transaction.date.day - 1;
      if (transaction.type == TransactionType.income) {
        dailyIncome[dayIndex] += transaction.amount;
      } else {
        dailyExpense[dayIndex] += transaction.amount;
      }
    }

    final maxIncome =
        dailyIncome.fold<double>(0, (max, value) => value > max ? value : max);
    final maxExpense =
        dailyExpense.fold<double>(0, (max, value) => value > max ? value : max);
    final maxY = ((maxIncome > maxExpense ? maxIncome : maxExpense) * 1.25)
        .clamp(1, double.infinity)
        .toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Harian: Pemasukan vs Pengeluaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lihat pergerakan harian dalam bulan terpilih',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _legendDot(AppTheme.income, 'Pemasukan'),
                const SizedBox(width: 16),
                _legendDot(AppTheme.expense, 'Pengeluaran'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 10,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      tooltipMargin: 10,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      tooltipBgColor: const Color(0xFF111827),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = group.x + 1;
                        final label =
                            rodIndex == 0 ? 'Pemasukan' : 'Pengeluaran';
                        return BarTooltipItem(
                          'Tgl $day\n$label\n${CurrencyFormatter.format(rod.toY)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: AppTheme.divider,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: totalDays > 20 ? 5 : 2,
                        getTitlesWidget: (value, meta) {
                          final day = value.toInt() + 1;
                          if (day < 1 || day > totalDays) {
                            return const SizedBox.shrink();
                          }
                          final shouldShow = day == 1 ||
                              day == totalDays ||
                              day % (totalDays > 20 ? 5 : 2) == 0;
                          if (!shouldShow) {
                            return const SizedBox.shrink();
                          }

                          return Text(
                            '$day',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(totalDays, (index) {
                    return BarChartGroupData(
                      x: index,
                      barsSpace: 3,
                      barRods: [
                        BarChartRodData(
                          toY: dailyIncome[index],
                          color: AppTheme.income,
                          width: 4,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2)),
                        ),
                        BarChartRodData(
                          toY: dailyExpense[index],
                          color: AppTheme.expense,
                          width: 4,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCategoryChart(
      FinanceProvider provider, List<TransactionModel> monthTransactions) {
    final categoryTotals = <String, _CategoryExpenseData>{};
    for (final transaction in monthTransactions) {
      if (transaction.type != TransactionType.expense) {
        continue;
      }

      final existing = categoryTotals[transaction.categoryName];
      if (existing == null) {
        categoryTotals[transaction.categoryName] = _CategoryExpenseData(
          name: transaction.categoryName,
          icon: transaction.categoryIcon,
          color: Color(transaction.categoryColor),
          amount: transaction.amount,
        );
      } else {
        categoryTotals[transaction.categoryName] = _CategoryExpenseData(
          name: existing.name,
          icon: existing.icon,
          color: existing.color,
          amount: existing.amount + transaction.amount,
        );
      }
    }

    final categories = categoryTotals.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final totalExpense =
        categories.fold<double>(0, (sum, item) => sum + item.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori Terbesar Bulan Ini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            _buildEmptyCard('Belum ada data pengeluaran di bulan ini')
          else
            _buildCategoryPieCard(categories, totalExpense, monthTransactions),
        ],
      ),
    );
  }

  Widget _buildCategoryPieCard(List<_CategoryExpenseData> categories,
      double totalExpense, List<TransactionModel> monthTransactions) {
    final safeTouchedIndex =
        _touchedCategoryIndex >= 0 && _touchedCategoryIndex < categories.length
            ? _touchedCategoryIndex
            : -1;
    final selected =
        safeTouchedIndex == -1 ? null : categories[safeTouchedIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 184,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 168,
                  height: 168,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            _touchedCategoryIndex =
                                response?.touchedSection?.touchedSectionIndex ??
                                    -1;
                          });
                        },
                      ),
                      centerSpaceRadius: 60,
                      sectionsSpace: 4,
                      sections: categories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value;
                        final isTouched = index == safeTouchedIndex;

                        return PieChartSectionData(
                          value: category.amount,
                          color: category.color,
                          title: '',
                          radius: isTouched ? 66 : 64,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.bgLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        selected?.icon ?? '\$',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selected?.name ?? 'Tidak dipilih',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: categories.map((category) {
              final percent =
                  totalExpense == 0 ? 0.0 : (category.amount / totalExpense);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${category.name} - ${(percent * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: category.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          ...categories.map((category) {
            final percent =
                totalExpense == 0 ? 0.0 : (category.amount / totalExpense);
            final categoryTransactions = monthTransactions
                .where((transaction) =>
                    transaction.type == TransactionType.expense &&
                    transaction.categoryName == category.name)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _CategoryDetailScreen(
                          month: _selectedMonth,
                          category: category,
                          transactions: categoryTransactions,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: category.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            category.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      category.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    CurrencyFormatter.format(category.amount),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  minHeight: 8,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    category.color,
                                  ),
                                  backgroundColor: AppTheme.divider,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${(percent * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(String label) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CategoryDetailScreen extends StatelessWidget {
  const _CategoryDetailScreen({
    required this.month,
    required this.category,
    required this.transactions,
  });

  final DateTime month;
  final _CategoryExpenseData category;
  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          '${category.icon} ${category.name}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatter.formatMonthYear(month),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(category.amount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: transactions.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada transaksi kategori ini',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : Consumer<FinanceProvider>(
                    builder: (context, provider, _) {
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TransactionTile(
                              transaction: transaction,
                              onDelete: () => provider.deleteTransaction(
                                transaction.id,
                              ),
                              onEdit: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => AddTransactionBottomSheet(
                                  transaction: transaction,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryExpenseData {
  const _CategoryExpenseData({
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
  });

  final String name;
  final String icon;
  final Color color;
  final double amount;
}
