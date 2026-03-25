// lib/screens/report_screen.dart

import 'package:Monetoo/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _selectedMonth = DateTime.now();
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: Text(
          'Laporan Keuangan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildMonthSelector()),
              SliverToBoxAdapter(
                child: FutureBuilder<Map<String, double>>(
                  future: provider.getMonthlySummary(
                    _selectedMonth.year,
                    _selectedMonth.month,
                  ),
                  builder: (context, snapshot) {
                    final income = snapshot.data?['income'] ?? 0;
                    final expense = snapshot.data?['expense'] ?? 0;
                    return _buildSummarySection(income, expense);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: provider.getDailyTotalsForMonth(
                    _selectedMonth.year,
                    _selectedMonth.month,
                  ),
                  builder: (context, snapshot) {
                    final data = snapshot.data ?? [];
                    return _buildBarChart(data);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: FutureBuilder<Map<String, double>>(
                  future: provider.getCategoryExpenseByMonth(
                    _selectedMonth.year,
                    _selectedMonth.month,
                  ),
                  builder: (context, snapshot) {
                    final data = snapshot.data ?? {};
                    return _buildCategoryPieChart(data);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: _buildDailyReport(provider),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector() {
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
          Text(
            DateFormatter.formatMonthYear(_selectedMonth),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
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
                  ? c.divider
                  : c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(double income, double expense) {
    final c = context.colors;
    final balance = income - expense;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Main balance card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Saldo Bulan Ini',
                  style: TextStyle(fontSize: 13, color: c.cardBg),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(balance),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: c.cardBg,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.cardBg.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _summaryItem('Total Masuk', income, c.income,
                          Icons.arrow_downward_rounded),
                    ),
                    Container(width: 1, height: 40, color: c.cardBg),
                    Expanded(
                      child: _summaryItem('Total Keluar', expense, c.expense,
                          Icons.arrow_upward_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Progress bar
          if (income > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: c.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Penggunaan Anggaran',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(
                        '${(expense / income * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: expense / income > 0.9 ? c.expense : c.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (expense / income).clamp(0, 1),
                      backgroundColor: c.bgLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        expense / income > 0.9 ? c.expense : c.accent,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double amount, Color color, IconData icon) {
    final c = context.colors;
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: c.cardBg)),
        Text(
          CurrencyFormatter.formatCompact(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: c.cardBg,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    final c = context.colors;
    if (data.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: c.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tren Harian',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _legendDot(c.income, 'Masuk'),
                const SizedBox(width: 16),
                _legendDot(c.expense, 'Keluar'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data
                          .map((e) =>
                              [e['income'] as double, e['expense'] as double])
                          .expand((e) => e)
                          .fold(0.0, (a, b) => a > b ? a : b) *
                      1.2,
                  barGroups: data.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final d = entry.value;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: (d['income'] as double),
                          color: c.income,
                          width: 6,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                        BarChartRodData(
                          toY: (d['expense'] as double),
                          color: c.expense,
                          width: 6,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: data.length <= 15,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          final dateStr = data[idx]['date'] as String;
                          final parts = dateStr.split('-');
                          return Text(
                            parts[2],
                            style: TextStyle(
                              fontSize: 9,
                              color: c.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: c.divider,
                      strokeWidth: 1,
                    ),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    final c = context.colors;
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary)),
      ],
    );
  }

  Widget _buildCategoryPieChart(Map<String, double> data) {
    final c = context.colors;
    if (data.isEmpty) return const SizedBox.shrink();

    final total = data.values.fold(0.0, (a, b) => a + b);
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      c.expense,
      c.accent,
      c.income,
      const Color(0xFFFFBE0B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFFFF922B),
      const Color(0xFF9D85FF),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: c.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengeluaran per Kategori',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            _touchedIndex =
                                response?.touchedSection?.touchedSectionIndex ??
                                    -1;
                          });
                        },
                      ),
                      sections: entries.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final e = entry.value;
                        final percent = e.value / total * 100;
                        final isTouched = idx == _touchedIndex;
                        final color = colors[idx % colors.length];

                        return PieChartSectionData(
                          value: e.value,
                          color: color,
                          radius: isTouched ? 50 : 42,
                          title:
                              isTouched ? '${percent.toStringAsFixed(1)}%' : '',
                          titleStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: c.cardBg,
                          ),
                        );
                      }).toList(),
                      centerSpaceRadius: 36,
                      sectionsSpace: 3,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: entries.take(6).map((e) {
                      final idx = entries.indexOf(e);
                      final color = colors[idx % colors.length];
                      final percent = e.value / total * 100;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key,
                                style: TextStyle(
                                    fontSize: 11, color: c.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${percent.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReport(FinanceProvider provider) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: c.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Laporan Harian',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<TransactionModel>>(
              future: provider.getTransactionsByMonth(
                  _selectedMonth.year, _selectedMonth.month),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final transactions = snapshot.data!;

                // Group by day
                final Map<String, List<TransactionModel>> groups = {};
                for (final t in transactions) {
                  final key =
                      '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
                  groups[key] ??= [];
                  groups[key]!.add(t);
                }

                final sortedKeys = groups.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                if (sortedKeys.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Tidak ada data untuk bulan ini',
                        style: TextStyle(color: c.textSecondary, fontSize: 13),
                      ),
                    ),
                  );
                }

                return Column(
                  children: sortedKeys.map((key) {
                    final dayTransactions = groups[key]!;
                    final date = dayTransactions.first.date;
                    final income = dayTransactions
                        .where((t) => t.type == TransactionType.income)
                        .fold(0.0, (s, t) => s + t.amount);
                    final expense = dayTransactions
                        .where((t) => t.type == TransactionType.expense)
                        .fold(0.0, (s, t) => s + t.amount);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.bgLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: c.cardBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: c.textPrimary,
                                    height: 1,
                                  ),
                                ),
                                Text(
                                  DateFormatter.formatShort(date).split(' ')[1],
                                  style: TextStyle(
                                      fontSize: 10, color: c.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${dayTransactions.length} transaksi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Saldo: ${CurrencyFormatter.formatCompact(income - expense)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: income - expense >= 0
                                        ? c.income
                                        : c.expense,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (income > 0)
                                Text(
                                  '+${CurrencyFormatter.formatCompact(income)}',
                                  style:
                                      TextStyle(fontSize: 11, color: c.income),
                                ),
                              if (expense > 0)
                                Text(
                                  '-${CurrencyFormatter.formatCompact(expense)}',
                                  style:
                                      TextStyle(fontSize: 11, color: c.expense),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
