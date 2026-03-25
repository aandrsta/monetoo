// lib/screens/statistics_screen.dart

import 'package:Monetoo/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_colors.dart';
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

  // 0 = pengeluaran, 1 = pemasukan
  int _chartTab = 0;
  late final PageController _chartPageController;

  @override
  void initState() {
    super.initState();
    _chartPageController = PageController(initialPage: _chartTab);
  }

  @override
  void dispose() {
    _chartPageController.dispose();
    super.dispose();
  }

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

  Future<void> _pickMonth(BuildContext context) async {
    final c = context.colors;
    int pickedYear = _selectedMonth.year;
    int pickedMonth = _selectedMonth.month;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Pilih Bulan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
                      icon: Icon(Icons.chevron_left_rounded),
                    ),
                    Text('$pickedYear',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    IconButton(
                      onPressed: () => setD(() => pickedYear++),
                      icon: Icon(Icons.chevron_right_rounded),
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
                                color: isSelected ? c.cardBg : c.textSecondary,
                              )),
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
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, provider, _) {
            final monthTx = provider.transactions
                .where((t) =>
                    t.date.year == _selectedMonth.year &&
                    t.date.month == _selectedMonth.month)
                .toList();

            final categoryColorMap = {
              for (final cat in [
                ...provider.expenseCategories,
                ...provider.incomeCategories
              ])
                cat.name: Color(cat.color)
            };

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildMonthSelector(context)),
                SliverToBoxAdapter(child: _buildMonthlyOverview(monthTx)),
                SliverToBoxAdapter(child: _buildDailyChart(monthTx)),
                SliverToBoxAdapter(
                    child: _buildPieSection(
                  title: 'Pengeluaran per Kategori',
                  type: TransactionType.expense,
                  transactions: monthTx,
                  touchedIndex: _touchedExpenseIndex,
                  onTouch: (i) => setState(() => _touchedExpenseIndex = i),
                  emptyLabel: 'Belum ada pengeluaran bulan ini',
                  categoryColorMap: categoryColorMap,
                )),
                SliverToBoxAdapter(
                    child: _buildPieSection(
                  title: 'Pemasukan per Kategori',
                  type: TransactionType.income,
                  transactions: monthTx,
                  touchedIndex: _touchedIncomeIndex,
                  onTouch: (i) => setState(() => _touchedIncomeIndex = i),
                  emptyLabel: 'Belum ada pemasukan bulan ini',
                  categoryColorMap: categoryColorMap,
                )),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text('Statistik',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700, color: c.textPrimary)),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
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
            onPressed: () => _changeMonth(1),
            icon: Icon(Icons.chevron_right_rounded, color: c.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyOverview(List<TransactionModel> txs) {
    final c = context.colors;
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
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: c.cardShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ringkasan Bulanan',
                style: TextStyle(fontSize: 14, color: c.textSecondary)),
            const SizedBox(height: 2),
            Text(DateFormatter.formatMonthYear(_selectedMonth),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _statCard('Pemasukan', income,
                      Icons.arrow_downward_rounded, c.income)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statCard('Pengeluaran', expense,
                      Icons.arrow_upward_rounded, c.expense)),
            ]),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Saldo Akhir',
                    style: TextStyle(fontSize: 14, color: c.textSecondary)),
                Text(CurrencyFormatter.format(balance),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: balance >= 0 ? c.income : c.expense)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, double amount, IconData icon, Color color) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
        const SizedBox(height: 4),
        Text(CurrencyFormatter.formatCompact(amount),
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  // ── DAILY CHART — tab slide pemasukan/pengeluaran ──
  Widget _buildDailyChart(List<TransactionModel> txs) {
    final c = context.colors;
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

    // Tanggal hari ini (hanya relevan kalau bulan yang dipilih = bulan ini)
    final now = DateTime.now();
    final todayIdx = _isCurrentMonth ? now.day - 1 : -1;

    // Subtitle: tanggal hari ini
    final todayLabel = _isCurrentMonth
        ? 'Hari ini: ${DateFormatter.formatShort(now)}'
        : DateFormatter.formatMonthYear(_selectedMonth);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: c.cardShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header + subtitle ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Harian',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              _isCurrentMonth
                                  ? Icons.today_rounded
                                  : Icons.calendar_month_rounded,
                              size: 12,
                              color:
                                  _isCurrentMonth ? c.accent : c.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              todayLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: _isCurrentMonth
                                    ? c.accent
                                    : c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Tab selector ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: c.bgLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _chartTabItem(0, 'Pengeluaran', c.expense),
                    _chartTabItem(1, 'Pemasukan', c.income),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── PageView chart ──
            SizedBox(
              height: 220,
              child: PageView(
                controller: _chartPageController,
                onPageChanged: (i) => setState(() => _chartTab = i),
                children: [
                  // Halaman 0: Pengeluaran
                  _chartPage(
                    data: dailyExpense,
                    color: c.expense,
                    totalDays: totalDays,
                    todayIdx: todayIdx,
                    label: 'Pengeluaran',
                  ),
                  // Halaman 1: Pemasukan
                  _chartPage(
                    data: dailyIncome,
                    color: c.income,
                    totalDays: totalDays,
                    todayIdx: todayIdx,
                    label: 'Pemasukan',
                  ),
                ],
              ),
            ),

            // ── Dot indicator ──
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(0),
                  const SizedBox(width: 6),
                  _dot(1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartTabItem(int index, String label, Color color) {
    final c = context.colors;
    final isSelected = _chartTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _chartTab = index);
          _chartPageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? c.cardBg : c.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(int index) {
    final c = context.colors;
    final isSelected = _chartTab == index;
    final color = index == 0 ? c.expense : c.income;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isSelected ? 18 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isSelected ? color : c.divider,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _chartPage({
    required List<double> data,
    required Color color,
    required int totalDays,
    required int todayIdx,
    required String label,
  }) {
    final c = context.colors;
    final maxVal = data.fold<double>(0, (m, v) => v > m ? v : m);
    final maxY = (maxVal * 1.25).clamp(1, double.infinity).toDouble();
    final total = data.fold<double>(0, (s, v) => s + v);
    final avg = total / totalDays;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini summary
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                _miniStat(
                    'Total', CurrencyFormatter.formatCompact(total), color),
                const SizedBox(width: 16),
                _miniStat('Rata-rata/hari',
                    CurrencyFormatter.formatCompact(avg), c.textSecondary),
              ],
            ),
          ),
          Expanded(
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
                  getTooltipItem: (group, _, rod, __) {
                    final day = group.x + 1;
                    final isToday = todayIdx == group.x;
                    return BarTooltipItem(
                      '${isToday ? 'Hari ini' : 'Tgl $day'}\n$label\n${CurrencyFormatter.format(rod.toY)}',
                      TextStyle(
                          color: c.cardBg,
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
                      FlLine(color: c.divider, strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, _) {
                      final day = value.toInt() + 1;
                      final isToday = value.toInt() == todayIdx;
                      // Tampilkan: hari pertama, terakhir, kelipatan 5, dan hari ini
                      final show = day == 1 ||
                          day == totalDays ||
                          day % 5 == 0 ||
                          isToday;
                      if (!show) return const SizedBox.shrink();
                      return Text(
                        isToday ? '●' : '$day',
                        style: TextStyle(
                          fontSize: isToday ? 10 : 10,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w400,
                          color: isToday ? color : c.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(
                  totalDays,
                  (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data[i],
                            // Bar hari ini dikasih warna lebih terang
                            color: i == todayIdx
                                ? color
                                : color.withValues(alpha: 0.65),
                            width: totalDays > 20 ? 7 : 10,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ],
                      )),
            )),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: c.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _buildPieSection({
    required String title,
    required TransactionType type,
    required List<TransactionModel> transactions,
    required int touchedIndex,
    required Function(int) onTouch,
    required String emptyLabel,
    required Map<String, Color> categoryColorMap,
  }) {
    final c = context.colors;
    final Map<String, _CatData> map = {};
    for (final t in transactions) {
      if (t.type != type) continue;
      final currentColor =
          categoryColorMap[t.categoryName] ?? Color(t.categoryColor);
      if (!map.containsKey(t.categoryName)) {
        map[t.categoryName] = _CatData(
          name: t.categoryName,
          icon: t.categoryIcon,
          color: currentColor,
          amount: 0,
        );
      } else {
        map[t.categoryName] = _CatData(
          name: map[t.categoryName]!.name,
          icon: map[t.categoryName]!.icon,
          color: currentColor,
          amount: map[t.categoryName]!.amount,
        );
      }
      map[t.categoryName] = map[t.categoryName]!.addAmount(t.amount);
    }

    final categories = map.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final total = categories.fold<double>(0, (s, c) => s + c.amount);
    final isExpense = type == TransactionType.expense;
    final accentColor = isExpense ? c.expense : c.income;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: c.cardShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary)),
                Text(CurrencyFormatter.formatCompact(total),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: accentColor)),
              ],
            ),
            const SizedBox(height: 20),
            if (categories.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(emptyLabel,
                      style: TextStyle(fontSize: 13, color: c.textSecondary)),
                ),
              )
            else ...[
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
                        return PieChartSectionData(
                          value: cat.amount,
                          color: cat.color,
                          radius: isTouched ? 56 : 48,
                          title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                          titleStyle: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: c.cardBg),
                          titlePositionPercentageOffset: 0.65,
                        );
                      }).toList(),
                    )),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: categories.asMap().entries.map((entry) {
                        final i = entry.key;
                        final cat = entry.value;
                        final pct = total == 0 ? 0.0 : cat.amount / total * 100;
                        final isTouched = i == touchedIndex;

                        return GestureDetector(
                          onTap: () => onTouch(isTouched ? -1 : i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isTouched
                                  ? cat.color.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: cat.color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(cat.name,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: isTouched
                                            ? c.textPrimary
                                            : c.textSecondary,
                                        fontWeight: isTouched
                                            ? FontWeight.w600
                                            : FontWeight.w400),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text('${pct.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: cat.color)),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: c.divider, height: 1),
              const SizedBox(height: 16),
              ...categories.map((cat) {
                final pct = total == 0 ? 0.0 : cat.amount / total;
                final catTxs = transactions
                    .where((t) => t.type == type && t.categoryName == cat.name)
                    .toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

                return GestureDetector(
                  onTap: () => _openCategoryDetail(context, cat, catTxs, type),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10)),
                          child: Center(
                              child: Text(cat.icon,
                                  style: TextStyle(fontSize: 19))),
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
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: c.textPrimary)),
                                ),
                                const SizedBox(width: 8),
                                Text(CurrencyFormatter.format(cat.amount),
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: c.textPrimary)),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded,
                                    size: 16, color: c.textSecondary),
                              ]),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(cat.color),
                                  backgroundColor: c.divider,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${catTxs.length} transaksi',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: c.textSecondary)),
                                  Text('${(pct * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: c.textSecondary)),
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

  void _openCategoryDetail(
    BuildContext context,
    _CatData cat,
    List<TransactionModel> transactions,
    TransactionType type,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CategoryDetailScreen(
          month: _selectedMonth,
          cat: cat,
          transactions: transactions,
          type: type,
        ),
      ),
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

  const _CategoryDetailScreen({
    required this.month,
    required this.cat,
    required this.transactions,
    required this.type,
  });

  @override
  State<_CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<_CategoryDetailScreen> {
  String _sort = 'date_desc';

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
      default:
        list.sort((a, b) => b.date.compareTo(a.date));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final txs = _sorted;
    final total = txs.fold<double>(0, (s, t) => s + t.amount);
    final avg = txs.isEmpty ? 0.0 : total / txs.length;
    final maxTx = txs.isEmpty
        ? 0.0
        : txs.map((t) => t.amount).reduce((a, b) => a > b ? a : b);
    final isExpense = widget.type == TransactionType.expense;
    final color = widget.cat.color;

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: c.cardBg,
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: c.textPrimary),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                            child: Text(widget.cat.icon,
                                style: TextStyle(fontSize: 18))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.cat.name,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: c.textPrimary)),
                            Text(DateFormatter.formatMonthYear(widget.month),
                                style: TextStyle(
                                    fontSize: 12, color: c.textSecondary)),
                          ],
                        ),
                      ),
                      Text(CurrencyFormatter.format(total),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isExpense ? c.expense : c.income)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _miniStat(
                          '${txs.length} transaksi', 'Total', c.textPrimary),
                      _statDivider(),
                      _miniStat(CurrencyFormatter.formatCompact(avg),
                          'Rata-rata', color),
                      _statDivider(),
                      _miniStat(CurrencyFormatter.formatCompact(maxTx),
                          'Terbesar', isExpense ? c.expense : c.income),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              color: c.cardBg,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _sortChip('Terbaru', 'date_desc', color),
                    const SizedBox(width: 8),
                    _sortChip('Terlama', 'date_asc', color),
                    const SizedBox(width: 8),
                    _sortChip('Terbesar', 'amount_desc', color),
                    const SizedBox(width: 8),
                    _sortChip('Terkecil', 'amount_asc', color),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: c.divider),
            Expanded(
              child: txs.isEmpty
                  ? Center(
                      child: Text('Belum ada transaksi',
                          style:
                              TextStyle(fontSize: 14, color: c.textSecondary)))
                  : Consumer<FinanceProvider>(
                      builder: (context, provider, _) => ListView.builder(
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
                                builder: (_) =>
                                    AddTransactionBottomSheet(transaction: tx),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    final c = context.colors;
    return Expanded(
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary)),
      ]),
    );
  }

  Widget _statDivider() => Container(
      width: 1,
      height: 28,
      color: AppTheme.divider,
      margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _sortChip(String label, String value, Color color) {
    final c = context.colors;
    final isSelected = _sort == value;
    return GestureDetector(
      onTap: () => setState(() => _sort = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : c.bgLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? c.cardBg : c.textSecondary,
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
