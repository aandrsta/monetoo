// lib/screens/account_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_colors.dart';
import '../utils/currency_formatter.dart';
import '../widgets/add_transaction_bottom_sheet.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/income_expense_summary.dart';
import '../widgets/transaction_filter_chips.dart';
import '../utils/app_toast.dart';
import '../widgets/common/bottom_sheet_handle.dart';
import '../models/transaction_model.dart';

class AccountDetailScreen extends StatefulWidget {
  final AccountModel account;
  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, provider, _) {
            final allTx = provider.transactions
                .where((t) => t.accountId == widget.account.id)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            final filtered = _filter == 'income'
                ? allTx.where((t) => t.type == TransactionType.income).toList()
                : _filter == 'expense'
                    ? allTx
                        .where((t) => t.type == TransactionType.expense)
                        .toList()
                    : allTx;

            final income = allTx.totalIncome;
            final expense = allTx.totalExpense;

            return Column(
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(widget.account.color)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                                child: Text(widget.account.icon,
                                    style: const TextStyle(fontSize: 20))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(widget.account.name,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: c.textPrimary)),
                                  if (widget.account.isPrimary) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.star,
                                        size: 13, color: Colors.amber),
                                  ],
                                ]),
                                Text('${allTx.length} transaksi',
                                    style: TextStyle(
                                        fontSize: 12, color: c.textSecondary)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(allTx.balance),
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: allTx.balance >= 0 ? c.income : c.expense),
                              ),
                              Text(
                                allTx.balance >= 0 ? 'Surplus' : 'Defisit',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: allTx.balance >= 0 ? c.income : c.expense),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      IncomeExpenseSummary(income: income, expense: expense),
                    ],
                  ),
                ),
                TransactionFilterChips(
                  selectedFilter: _filter,
                  onChanged: (v) => setState(() => _filter = v),
                ),
                Container(height: 1, color: c.divider),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  size: 56, color: c.divider),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada transaksi\ndi akun ini',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: c.textSecondary,
                                    height: 1.5),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final tx = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TransactionTile(
                                transaction: tx,
                                onDelete: () => provider.deleteTransaction(tx.id),
                                onEdit: () => AddTransactionBottomSheet.show(context, transaction: tx),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
