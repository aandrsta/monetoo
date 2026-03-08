// lib/utils/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/account_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('keuangan.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        type TEXT NOT NULL,
        isDefault INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        categoryName TEXT NOT NULL,
        categoryIcon TEXT NOT NULL,
        categoryColor INTEGER NOT NULL,
        accountId TEXT,
        date TEXT NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        isPrimary INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // Insert default categories
    for (final cat in getDefaultCategories()) {
      await db.insert('categories', cat.toMap());
    }

    // Insert default accounts
    for (final acc in getDefaultAccounts()) {
      await db.insert('accounts', acc.toMap());
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE accounts (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          icon TEXT NOT NULL,
          color INTEGER NOT NULL,
          isPrimary INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL
        )
      ''');

      // Insert default accounts
      for (final acc in getDefaultAccounts()) {
        await db.insert('accounts', acc.toMap());
      }
    }

    if (oldVersion < 3) {
      // Add accountId column to transactions table
      await db.execute('''
        ALTER TABLE transactions ADD COLUMN accountId TEXT
      ''');
    }
  }

  // ===== CATEGORY OPERATIONS =====

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'createdAt ASC');
    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<List<CategoryModel>> getCategoriesByType(TransactionType type) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'isDefault DESC, name ASC',
    );
    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<String> insertCategory(CategoryModel category) async {
    final db = await database;
    await db.insert('categories', category.toMap());
    return category.id;
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ===== TRANSACTION OPERATIONS =====

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final result =
        await db.query('transactions', orderBy: 'date DESC, createdAt DESC');
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByDate(DateTime date) async {
    final db = await database;
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end =
        DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final result = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start, end],
      orderBy: 'date DESC, createdAt DESC',
    );
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(
      DateTime startDate, DateTime endDate) async {
    final db = await database;
    final start = DateTime(startDate.year, startDate.month, startDate.day)
        .toIso8601String();
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
        .toIso8601String();

    final result = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start, end],
      orderBy: 'date DESC',
    );
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByMonth(
      int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    return getTransactionsByDateRange(startDate, endDate);
  }

  Future<String> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toMap());
    return transaction.id;
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ===== SUMMARY OPERATIONS =====

  Future<Map<String, double>> getDailySummary(DateTime date) async {
    final transactions = await getTransactionsByDate(date);
    double income = 0;
    double expense = 0;

    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final transactions = await getTransactionsByMonth(year, month);
    double income = 0;
    double expense = 0;

    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  Future<Map<String, double>> getCategoryExpenseByMonth(
      int year, int month) async {
    final transactions = await getTransactionsByMonth(year, month);
    final Map<String, double> result = {};

    for (final t in transactions) {
      if (t.type == TransactionType.expense) {
        result[t.categoryName] = (result[t.categoryName] ?? 0) + t.amount;
      }
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getDailyTotalsForMonth(
      int year, int month) async {
    final transactions = await getTransactionsByMonth(year, month);
    final Map<String, Map<String, double>> dailyMap = {};

    for (final t in transactions) {
      final dayKey =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      dailyMap[dayKey] ??= {'income': 0, 'expense': 0};
      if (t.type == TransactionType.income) {
        dailyMap[dayKey]!['income'] =
            (dailyMap[dayKey]!['income'] ?? 0) + t.amount;
      } else {
        dailyMap[dayKey]!['expense'] =
            (dailyMap[dayKey]!['expense'] ?? 0) + t.amount;
      }
    }

    return dailyMap.entries
        .map((e) => {
              'date': e.key,
              'income': e.value['income'],
              'expense': e.value['expense']
            })
        .toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  // ===== ACCOUNT OPERATIONS =====

  Future<List<AccountModel>> getAllAccounts() async {
    final db = await database;
    final result =
        await db.query('accounts', orderBy: 'isPrimary DESC, createdAt ASC');
    return result.map((e) => AccountModel.fromMap(e)).toList();
  }

  Future<List<AccountModel>> getAccountsByType(AccountType type) async {
    final db = await database;
    final result = await db.query(
      'accounts',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'isPrimary DESC, name ASC',
    );
    return result.map((e) => AccountModel.fromMap(e)).toList();
  }

  Future<AccountModel?> getPrimaryAccount() async {
    final db = await database;
    final result = await db.query(
      'accounts',
      where: 'isPrimary = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return AccountModel.fromMap(result.first);
  }

  Future<String> insertAccount(AccountModel account) async {
    final db = await database;
    // If this is primary, remove primary from others
    if (account.isPrimary) {
      await db.update(
        'accounts',
        {'isPrimary': 0},
        where: 'isPrimary = ?',
        whereArgs: [1],
      );
    }
    await db.insert('accounts', account.toMap());
    return account.id;
  }

  Future<int> updateAccount(AccountModel account) async {
    final db = await database;
    // If this is primary, remove primary from others
    if (account.isPrimary) {
      await db.update(
        'accounts',
        {'isPrimary': 0},
        where: 'isPrimary = ? AND id != ?',
        whereArgs: [1, account.id],
      );
    }
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(String id) async {
    final db = await database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
