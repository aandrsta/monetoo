// lib/screens/category_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_toast.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/add_transaction_bottom_sheet.dart';

class CategoryDetailScreen extends StatefulWidget {
  final DateTime month;
  final CategoryStatData cat;
  final List<TransactionModel> transactions;
  final TransactionType type;

  const CategoryDetailScreen({
    super.key,
    required this.month,
    required this.cat,
    required this.transactions,
    required this.type,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
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
    final color = Color(widget.cat.color);

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
                                style: const TextStyle(fontSize: 18))),
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
                              onEdit: () => AddTransactionBottomSheet.show(context, transaction: tx),
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
