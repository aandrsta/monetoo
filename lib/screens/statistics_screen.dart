// lib/screens/statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_toast.dart';
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
  int _touchedExpenseIndex = -1;
  int _touchedIncomeIndex = -1;

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

  // Warna palette konsisten untuk chart
  static const List<Color> _chartColors = [
    Color(0xFFFF5C7A),
    Color(0xFF7C6FFF),
    Color(0xFF00D4AA),
    Color(0xFFFFBE0B),
    Color(0xFF4ECDC4),
    Color(0xFF45B7D1),
    Color(0xFFFF922B),
    Color(0xFF9D85FF),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, provider, _) {
            final monthTx = provider.transactions
                .where((t) =>
                    t.date.year == _selectedMonth.year &&
                    t.date.month == _selectedMonth.month)
                .toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildMonthSelector()),
                SliverToBoxAdapter(child: _buildMonthlyOverview(monthTx)),
                SliverToBoxAdapter(child: _buildDailyChart(monthTx)),
                // Pie chart pengeluaran
                SliverToBoxAdapter(
                    child: _buildPieSection(
                  title: 'Pengeluaran per Kategori',
                  type: TransactionType.expense,
                  transactions: monthTx,
                  touchedIndex: _touchedExpenseIndex,
                  onTouch: (i) => setState(() => _touchedExpenseIndex = i),
                  emptyLabel: 'Belum ada pengeluaran bulan ini',
                )),
                // Pie chart pemasukan
                SliverToBoxAdapter(
                    child: _buildPieSection(
                  title: 'Pemasukan per Kategori',
                  type: TransactionType.income,
                  transactions: monthTx,
                  touchedIndex: _touchedIncomeIndex,
                  onTouch: (i) => setState(() => _touchedIncomeIndex = i),
                  emptyLabel: 'Belum ada pemasukan bulan ini',
                )),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── HEADER ──

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(
        'Statistik',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  // ── MONTH SELECTOR ──

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
                color: AppTheme.textPrimary),
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

  // ── MONTHLY OVERVIEW ──

  Widget _buildMonthlyOverview(List<TransactionModel> txs) {
    final income = txs
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = txs
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (s, t) => s + t.amount);
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
            const Text('Ringkasan Bulanan',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text(
              DateFormatter.formatMonthYear(_selectedMonth),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _statCard('Pemasukan', income,
                        Icons.arrow_downward_rounded, AppTheme.income)),
                const SizedBox(width: 12),
                Expanded(
                    child: _statCard('Pengeluaran', expense,
                        Icons.arrow_upward_rounded, AppTheme.expense)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saldo Akhir',
                    style:
                        TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
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

  Widget _statCard(String label, double amount, IconData icon, Color color) {
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
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(height: 4),
          Text(CurrencyFormatter.formatCompact(amount),
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  // ── DAILY BAR CHART ──

  Widget _buildDailyChart(List<TransactionModel> txs) {
    final totalDays =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final dailyIncome = List<double>.filled(totalDays, 0);
    final dailyExpense = List<double>.filled(totalDays, 0);

    for (final t in txs) {
      final idx = t.date.day - 1;
      if (t.type == TransactionType.income) {
        dailyIncome[idx] += t.amount;
      } else {
        dailyExpense[idx] += t.amount;
      }
    }

    final maxVal = [...dailyIncome, ...dailyExpense]
        .fold<double>(0, (m, v) => v > m ? v : m);
    final maxY = (maxVal * 1.25).clamp(1, double.infinity).toDouble();

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
            const Text('Harian',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Row(children: [
              _legendDot(AppTheme.income, 'Pemasukan'),
              const SizedBox(width: 16),
              _legendDot(AppTheme.expense, 'Pengeluaran'),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 10,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipBgColor: const Color(0xFF111827),
                    getTooltipItem: (group, _, rod, rodIndex) {
                      final label = rodIndex == 0 ? 'Pemasukan' : 'Pengeluaran';
                      return BarTooltipItem(
                        'Tgl ${group.x + 1}\n$label\n${CurrencyFormatter.format(rod.toY)}',
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.35),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppTheme.divider, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, _) {
                        final day = value.toInt() + 1;
                        final show = day == 1 ||
                            day == totalDays ||
                            day % (totalDays > 20 ? 5 : 2) == 0;
                        if (!show) return const SizedBox.shrink();
                        return Text('$day',
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.textSecondary));
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  totalDays,
                  (i) => BarChartGroupData(
                    x: i,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                        toY: dailyIncome[i],
                        color: AppTheme.income,
                        width: 4,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2)),
                      ),
                      BarChartRodData(
                        toY: dailyExpense[i],
                        color: AppTheme.expense,
                        width: 4,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2)),
                      ),
                    ],
                  ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  // ── PIE CHART SECTION (dipakai untuk expense & income) ──

  Widget _buildPieSection({
    required String title,
    required TransactionType type,
    required List<TransactionModel> transactions,
    required int touchedIndex,
    required Function(int) onTouch,
    required String emptyLabel,
  }) {
    // Hitung total per kategori
    final Map<String, _CatData> map = {};
    for (final t in transactions) {
      if (t.type != type) continue;
      if (!map.containsKey(t.categoryName)) {
        map[t.categoryName] = _CatData(
          name: t.categoryName,
          icon: t.categoryIcon,
          color: Color(t.categoryColor),
          amount: 0,
        );
      }
      map[t.categoryName] = map[t.categoryName]!.addAmount(t.amount);
    }

    final categories = map.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final total = categories.fold<double>(0, (s, c) => s + c.amount);

    final isExpense = type == TransactionType.expense;
    final accentColor = isExpense ? AppTheme.expense : AppTheme.income;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
            // Title + total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                Text(
                  CurrencyFormatter.formatCompact(total),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (categories.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(emptyLabel,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                ),
              )
            else ...[
              // ── Pie chart + legend berdampingan ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: PieChart(PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, resp) {
                          onTouch(
                              resp?.touchedSection?.touchedSectionIndex ?? -1);
                        },
                      ),
                      centerSpaceRadius: 36,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                      sections: categories.asMap().entries.map((entry) {
                        final i = entry.key;
                        final cat = entry.value;
                        final isTouched = i == touchedIndex;
                        final pct = total == 0 ? 0.0 : cat.amount / total * 100;
                        final color = _colorForCategory(cat, i);
                        return PieChartSectionData(
                          value: cat.amount,
                          color: color,
                          radius: isTouched ? 56 : 48,
                          title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          titlePositionPercentageOffset: 0.65,
                        );
                      }).toList(),
                    )),
                  ),
                  const SizedBox(width: 20),
                  // Legend
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: categories.asMap().entries.map((entry) {
                        final i = entry.key;
                        final cat = entry.value;
                        final pct = total == 0 ? 0.0 : cat.amount / total * 100;
                        final isTouched = i == touchedIndex;
                        final color = _colorForCategory(cat, i);

                        return GestureDetector(
                          onTap: () => onTouch(isTouched ? -1 : i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isTouched
                                  ? color.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isTouched
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                    fontWeight: isTouched
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${pct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color),
                              ),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppTheme.divider, height: 1),
              const SizedBox(height: 16),

              // ── Bar per kategori (klik → detail) ──
              ...categories.map((cat) {
                final pct = total == 0 ? 0.0 : cat.amount / total;
                final color = _colorForCategory(cat, categories.indexOf(cat));
                final catTxs = transactions
                    .where((t) => t.type == type && t.categoryName == cat.name)
                    .toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

                return GestureDetector(
                  onTap: () =>
                      _openCategoryDetail(context, cat, catTxs, type, color),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                              child: Text(cat.icon,
                                  style: const TextStyle(fontSize: 19))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                  child: Text(cat.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  CurrencyFormatter.format(cat.amount),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded,
                                    size: 16, color: AppTheme.textSecondary),
                              ]),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                  backgroundColor: AppTheme.divider,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${catTxs.length} transaksi',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary),
                                  ),
                                  Text(
                                    '${(pct * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // ── OPEN DETAIL ──

  void _openCategoryDetail(
    BuildContext context,
    _CatData cat,
    List<TransactionModel> transactions,
    TransactionType type,
    Color color,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CategoryDetailScreen(
          month: _selectedMonth,
          cat: cat,
          transactions: transactions,
          type: type,
          color: color,
        ),
      ),
    );
  }

  // ── HELPERS ──

  Color _colorForCategory(_CatData cat, int index) {
    // Gunakan warna dari data kategori kalau tersedia,
    // fallback ke palette chart
    if (cat.color != Colors.transparent &&
        cat.color != const Color(0xFF000000)) {
      return cat.color;
    }
    return _chartColors[index % _chartColors.length];
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// CATEGORY DETAIL SCREEN
// ─────────────────────────────────────────────

class _CategoryDetailScreen extends StatefulWidget {
  final DateTime month;
  final _CatData cat;
  final List<TransactionModel> transactions;
  final TransactionType type;
  final Color color;

  const _CategoryDetailScreen({
    required this.month,
    required this.cat,
    required this.transactions,
    required this.type,
    required this.color,
  });

  @override
  State<_CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<_CategoryDetailScreen> {
  String _sort = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc

  List<TransactionModel> get _sorted {
    final list = List<TransactionModel>.from(widget.transactions);
    switch (_sort) {
      case 'date_asc':
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'amount_desc':
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      default: // date_desc
        list.sort((a, b) => b.date.compareTo(a.date));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final txs = _sorted;
    final total = txs.fold<double>(0, (s, t) => s + t.amount);
    final avg = txs.isEmpty ? 0.0 : total / txs.length;
    final maxTx = txs.isEmpty
        ? 0.0
        : txs.map((t) => t.amount).reduce((a, b) => a > b ? a : b);
    final isExpense = widget.type == TransactionType.expense;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
              child: Column(
                children: [
                  // Back + title
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: AppTheme.textPrimary),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                            child: Text(widget.cat.icon,
                                style: const TextStyle(fontSize: 18))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.cat.name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary)),
                            Text(
                              DateFormatter.formatMonthYear(widget.month),
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(total),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color:
                                isExpense ? AppTheme.expense : AppTheme.income),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      _miniStat('${txs.length} transaksi', 'Total',
                          AppTheme.textPrimary),
                      _statDivider(),
                      _miniStat(CurrencyFormatter.formatCompact(avg),
                          'Rata-rata', widget.color),
                      _statDivider(),
                      _miniStat(
                          CurrencyFormatter.formatCompact(maxTx),
                          'Terbesar',
                          isExpense ? AppTheme.expense : AppTheme.income),
                    ],
                  ),
                ],
              ),
            ),

            // ── SORT BAR ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _sortChip('Terbaru', 'date_desc'),
                    const SizedBox(width: 8),
                    _sortChip('Terlama', 'date_asc'),
                    const SizedBox(width: 8),
                    _sortChip('Terbesar', 'amount_desc'),
                    const SizedBox(width: 8),
                    _sortChip('Terkecil', 'amount_asc'),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: AppTheme.divider),

            // ── TRANSACTION LIST ──
            Expanded(
              child: txs.isEmpty
                  ? const Center(
                      child: Text('Belum ada transaksi',
                          style: TextStyle(
                              fontSize: 14, color: AppTheme.textSecondary)),
                    )
                  : Consumer<FinanceProvider>(
                      builder: (context, provider, _) {
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: txs.length,
                          itemBuilder: (context, index) {
                            final tx = txs[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TransactionTile(
                                transaction: tx,
                                onDelete: () {
                                  provider.deleteTransaction(tx.id);
                                  AppToast.success(
                                      context, 'Transaksi berhasil dihapus');
                                  Navigator.pop(context);
                                },
                                onEdit: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => AddTransactionBottomSheet(
                                      transaction: tx),
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
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
        width: 1,
        height: 28,
        color: AppTheme.divider,
        margin: const EdgeInsets.symmetric(horizontal: 4));
  }

  Widget _sortChip(String label, String value) {
    final isSelected = _sort == value;
    return GestureDetector(
      onTap: () => setState(() => _sort = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? widget.color : AppTheme.bgLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────

class _CatData {
  final String name;
  final String icon;
  final Color color;
  final double amount;

  const _CatData({
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
  });

  _CatData addAmount(double more) => _CatData(
        name: name,
        icon: icon,
        color: color,
        amount: amount + more,
      );
}
