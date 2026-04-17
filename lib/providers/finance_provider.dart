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

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalOpeningBalance =>
      _accounts.fold(0, (sum, a) => sum + a.openingBalance);

  double get balance => totalOpeningBalance + totalIncome - totalExpense;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final categoriesFuture = _db.getAllCategories();
    final accountsFuture = _db.getAllAccounts();
    final transactionsFuture = _db.getAllTransactions();

    _categories = await categoriesFuture;
    _accounts = await accountsFuture;
    _transactions = await transactionsFuture;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories({bool shouldNotify = true}) async {
    _categories = await _db.getAllCategories();
    if (shouldNotify) {
      notifyListeners();
    }
  }

  Future<void> loadAccounts({bool shouldNotify = true}) async {
    _accounts = await _db.getAllAccounts();
    if (shouldNotify) {
      notifyListeners();
    }
  }

  Future<void> loadTransactions({bool shouldNotify = true}) async {
    _transactions = await _db.getAllTransactions();
    if (shouldNotify) {
      notifyListeners();
    }
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
    await _db.updateTransactionsByCategory(category); // ← tambah ini
    await loadCategories();
    await loadTransactions(); // ← tambah ini
  }

  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    await loadCategories();
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
    // Get account opening balance
    final account = _accounts.firstWhere((a) => a.id == accountId,
        orElse: () => AccountModel(
            id: accountId,
            name: '',
            type: AccountType.cash,
            icon: '',
            color: 0,
            openingBalance: 0.0,
            createdAt: DateTime.now()));

    // Calculate transactions for this account
    final txs = _transactions.where((t) => t.accountId == accountId);
    final income = txs
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = txs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    return account.openingBalance + income - expense;
  }

  double getOpeningBalanceForMonth(int year, int month) {
    final startOfMonth = DateTime(year, month, 1);

    // Total opening balance of all accounts
    final totalInitialBalance =
        _accounts.fold(0.0, (sum, a) => sum + a.openingBalance);

    // Sum of transactions before this month
    final historicalTransactions =
        _transactions.where((t) => t.date.isBefore(startOfMonth));

    final income = historicalTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final expense = historicalTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return totalInitialBalance + income - expense;
  }
}
