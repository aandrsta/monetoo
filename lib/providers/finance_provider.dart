// lib/providers/finance_provider.dart

import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/account_model.dart';
import '../utils/database_helper.dart';

class FinanceProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  List<AccountModel> _accounts = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  List<AccountModel> get accounts => _accounts;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;

  List<CategoryModel> get expenseCategories =>
      _categories.where((c) => c.type == TransactionType.expense).toList();

  List<CategoryModel> get incomeCategories =>
      _categories.where((c) => c.type == TransactionType.income).toList();

  List<AccountModel> get regularAccounts =>
      _accounts.where((a) => a.type != AccountType.savings).toList();

  List<AccountModel> get savingsAccounts =>
      _accounts.where((a) => a.type == AccountType.savings).toList();

  AccountModel? get primaryAccount =>
      _accounts.where((a) => a.isPrimary).isNotEmpty
          ? _accounts.firstWhere((a) => a.isPrimary)
          : null;

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await loadCategories();
    await loadAccounts();
    await loadTransactions();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _categories = await _db.getAllCategories();
    notifyListeners();
  }

  Future<void> loadAccounts() async {
    _accounts = await _db.getAllAccounts();
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    _transactions = await _db.getAllTransactions();
    notifyListeners();
  }

  Future<List<TransactionModel>> getTransactionsByDate(DateTime date) async {
    return await _db.getTransactionsByDate(date);
  }

  Future<List<TransactionModel>> getTransactionsByMonth(
      int year, int month) async {
    return await _db.getTransactionsByMonth(year, month);
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // ===== TRANSACTIONS =====

  Future<void> addTransaction(TransactionModel transaction) async {
    await _db.insertTransaction(transaction);
    await loadTransactions();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _db.updateTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    await loadTransactions();
  }

  // ===== CATEGORIES =====

  Future<void> addCategory(CategoryModel category) async {
    await _db.insertCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _db.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    await loadCategories();
  }

  // ===== REPORT DATA =====

  Future<Map<String, double>> getDailySummary(DateTime date) async {
    return await _db.getDailySummary(date);
  }

  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    return await _db.getMonthlySummary(year, month);
  }

  Future<Map<String, double>> getCategoryExpenseByMonth(
      int year, int month) async {
    return await _db.getCategoryExpenseByMonth(year, month);
  }

  Future<List<Map<String, dynamic>>> getDailyTotalsForMonth(
      int year, int month) async {
    return await _db.getDailyTotalsForMonth(year, month);
  }

  List<TransactionModel> getRecentTransactions({int limit = 5}) {
    final sorted = List<TransactionModel>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  Map<String, double> getExpensesByCategory() {
    final Map<String, double> result = {};
    for (final t in _transactions) {
      if (t.type == TransactionType.expense) {
        result[t.categoryName] = (result[t.categoryName] ?? 0) + t.amount;
      }
    }
    return result;
  }

  Map<String, double> getIncomesByCategory() {
    final Map<String, double> result = {};
    for (final t in _transactions) {
      if (t.type == TransactionType.income) {
        result[t.categoryName] = (result[t.categoryName] ?? 0) + t.amount;
      }
    }
    return result;
  }

  Map<String, int> getTransactionCountByCategory(TransactionType type) {
    final Map<String, int> result = {};
    for (final t in _transactions) {
      if (t.type == type) {
        result[t.categoryName] = (result[t.categoryName] ?? 0) + 1;
      }
    }
    return result;
  }

  // ===== ACCOUNTS =====

  Future<void> addAccount(AccountModel account) async {
    await _db.insertAccount(account);
    await loadAccounts();
  }

  Future<void> updateAccount(AccountModel account) async {
    await _db.updateAccount(account);
    await loadAccounts();
  }

  Future<void> deleteAccount(String id) async {
    await _db.deleteAccount(id);
    await loadAccounts();
  }

  double getAccountBalance(String accountId) {
    // For now, calculate total balance
    // Later can be filtered by accountId when we add accountId to transactions
    return balance;
  }
}
