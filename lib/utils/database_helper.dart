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
      version: 6,
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
        openingBalance REAL NOT NULL DEFAULT 0,
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

    if (oldVersion < 4) {
      // Add openingBalance column to accounts table
      await db.execute('''
        ALTER TABLE accounts ADD COLUMN openingBalance REAL DEFAULT 0
      ''');
    }

    if (oldVersion < 6) {
      // Add indexes for performance
      await db.execute('CREATE INDEX idx_tx_date ON transactions(date)');
      await db.execute('CREATE INDEX idx_tx_category ON transactions(categoryId)');
      await db.execute('CREATE INDEX idx_tx_account ON transactions(accountId)');
    }

    // Settings now use SharedPreferences instead of database
  }

  // ===== CATEGORY OPERATIONS =====

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'createdAt ASC');
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

  Future<int> deleteCategory(String id, {String? fallbackId}) async {
    final db = await database;
    
    // 1. Get the category to be deleted to know its type
    final List<Map<String, dynamic>> cats = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (cats.isNotEmpty) {
      final type = cats.first['type'];
      final targetFallbackId = fallbackId ?? 
          (type == 'income' ? 'cat_lainnya_income' : 'cat_lainnya_expense');

      // 2. Get fallback category details to update transactions denormalized data
      final List<Map<String, dynamic>> fallbacks = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [targetFallbackId],
      );

      if (fallbacks.isNotEmpty) {
        final f = fallbacks.first;
        // 3. Update transactions to fallback category
        await db.update(
          'transactions',
          {
            'categoryId': f['id'],
            'categoryName': f['name'],
            'categoryIcon': f['icon'],
            'categoryColor': f['color'],
          },
          where: 'categoryId = ?',
          whereArgs: [id],
        );
      }
    }

    // 4. Finally delete the category
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ===== TRANSACTION OPERATIONS =====

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final result =
        await db.query('transactions', orderBy: 'date DESC, createdAt DESC');
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

  Future<int> updateTransactionsByCategory(CategoryModel category) async {
    final db = await database;
    return await db.update(
      'transactions',
      {
        'categoryName': category.name,
        'categoryIcon': category.icon,
        'categoryColor': category.color,
      },
      where: 'categoryId = ?',
      whereArgs: [category.id],
    );
  }

  // ===== SUMMARY OPERATIONS =====


  // ===== ACCOUNT OPERATIONS =====

  Future<List<AccountModel>> getAllAccounts() async {
    final db = await database;
    final result =
        await db.query('accounts', orderBy: 'isPrimary DESC, createdAt ASC');
    return result.map((e) => AccountModel.fromMap(e)).toList();
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
    
    // 1. Set accountId to null for all transactions in this account
    // This preserves the transaction data while removing the link to the deleted account
    await db.update(
      'transactions',
      {'accountId': null},
      where: 'accountId = ?',
      whereArgs: [id],
    );

    // 2. Delete the account
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
