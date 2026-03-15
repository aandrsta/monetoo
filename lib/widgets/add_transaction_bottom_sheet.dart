// lib/widgets/add_transaction_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/account_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_toast.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  final CategoryModel? initialCategory;
  final TransactionModel? transaction;

  const AddTransactionBottomSheet({
    super.key,
    this.initialCategory,
    this.transaction,
  });

  @override
  State<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  String _amount = '0';
  String _displayAmount = '0';
  double? _previousValue;
  String? _operation;
  bool _shouldResetAmount = false;
  bool _isNoteEditorVisible = false;
  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  DateTime _selectedDate = DateTime.now();
  String _note = '';
  late final TextEditingController _noteController;

  TransactionType _selectedType = TransactionType.expense;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    if (_isEditing) {
      final t = widget.transaction!;
      _amount = t.amount.toStringAsFixed(0);
      _displayAmount = _amount;
      _selectedDate = t.date;
      _note = t.note ?? '';
      _noteController.text = _note;
      _selectedType = t.type;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<FinanceProvider>();
        final categories = [
          ...provider.expenseCategories,
          ...provider.incomeCategories
        ];
        setState(() {
          _selectedCategory = categories.firstWhere(
            (cat) => cat.id == t.categoryId,
            orElse: () => categories.first,
          );
          final accounts = [
            ...provider.regularAccounts,
            ...provider.savingsAccounts
          ];
          if (accounts.isEmpty) {
            _selectedAccount = null;
          } else if (t.accountId != null) {
            try {
              _selectedAccount =
                  accounts.firstWhere((acc) => acc.id == t.accountId);
            } catch (_) {
              try {
                _selectedAccount = accounts.firstWhere((acc) => acc.isPrimary);
              } catch (_) {
                _selectedAccount = accounts.first;
              }
            }
          } else {
            try {
              _selectedAccount = accounts.firstWhere((acc) => acc.isPrimary);
            } catch (_) {
              _selectedAccount = accounts.first;
            }
          }
        });
      });
    } else {
      if (widget.initialCategory != null) {
        _selectedCategory = widget.initialCategory;
        _selectedType = widget.initialCategory!.type;
      }
      _noteController.text = _note;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<FinanceProvider>();
        final accounts = [
          ...provider.regularAccounts,
          ...provider.savingsAccounts
        ];
        setState(() {
          if (accounts.isEmpty) {
            _selectedAccount = null;
          } else {
            try {
              _selectedAccount = accounts.firstWhere((acc) => acc.isPrimary);
            } catch (_) {
              _selectedAccount = accounts.first;
            }
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
      if (_selectedCategory != null && _selectedCategory!.type != type) {
        _selectedCategory = null;
      }
    });
  }

  // ── KALKULATOR ──

  void _onNumberPressed(String number) {
    setState(() {
      if (_shouldResetAmount) {
        _amount = number;
        _shouldResetAmount = false;
      } else if (_amount == '0') {
        _amount = number;
      } else if (_amount.length < 15) {
        _amount += number;
      }
      _updateDisplay();
    });
  }

  void _onDoubleZeroPressed() {
    setState(() {
      if (_shouldResetAmount) {
        _amount = '0';
        _shouldResetAmount = false;
      } else if (_amount != '0' && _amount.length < 14) {
        _amount += '00';
      }
      _updateDisplay();
    });
  }

  void _onOperatorPressed(String op) {
    setState(() {
      if (_previousValue != null && _operation != null && !_shouldResetAmount) {
        _calculateInternal();
      }
      _previousValue = double.tryParse(_amount.isEmpty ? '0' : _amount) ?? 0;
      _operation = op;
      _shouldResetAmount = true;
      _updateDisplay();
    });
  }

  void _calculateInternal() {
    if (_previousValue == null || _operation == null) return;
    final current = double.tryParse(_amount.isEmpty ? '0' : _amount) ?? 0;
    double result = _previousValue!;
    switch (_operation) {
      case '+':
        result = _previousValue! + current;
        break;
      case '-':
        result = _previousValue! - current;
        break;
      case '×':
        result = _previousValue! * current;
        break;
      case '÷':
        if (current != 0) result = _previousValue! / current;
        break;
    }
    if (result == result.truncateToDouble()) {
      _amount = result.toInt().toString();
    } else {
      _amount = result.toString().replaceAll(RegExp(r'\.?0+$'), '');
    }
    _previousValue = null;
    _operation = null;
    _shouldResetAmount = false;
  }

  void _onEqualsPressed() {
    if (_previousValue == null || _operation == null) return;
    setState(() {
      _calculateInternal();
      _updateDisplay();
    });
  }

  void _updateDisplay() {
    if (_previousValue != null && _operation != null) {
      final firstNum = _formatNumberDisplay(_previousValue!);
      final secondNum = _shouldResetAmount
          ? '0'
          : _formatNumberDisplay(double.tryParse(_amount) ?? 0);
      _displayAmount = '$firstNum $_operation $secondNum';
    } else {
      _displayAmount = _amount;
    }
  }

  String _formatNumberDisplay(double number) {
    if (number == number.truncateToDouble()) {
      return NumberFormat('#,###', 'id_ID')
          .format(number.toInt())
          .replaceAll(',', '.');
    }
    return NumberFormat('#,##0.##', 'id_ID')
        .format(number)
        .replaceAll(',', '.');
  }

  void _onBackspace() {
    setState(() {
      if (_shouldResetAmount && _previousValue != null) {
        _amount = _previousValue!.truncateToDouble() == _previousValue!
            ? _previousValue!.toInt().toString()
            : _previousValue!.toString();
        _previousValue = null;
        _operation = null;
        _shouldResetAmount = false;
      } else if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
      _updateDisplay();
    });
  }

  void _onClear() {
    setState(() {
      _amount = '0';
      _previousValue = null;
      _operation = null;
      _shouldResetAmount = false;
      _updateDisplay();
    });
  }

  // ── SIMPAN ──

  void _onSave() async {
    // Validasi kategori — toast muncul di atas sheet, tidak ketutup
    if (_selectedCategory == null) {
      AppToast.error(context, 'Pilih kategori terlebih dahulu');
      return;
    }

    // Selesaikan kalkulasi pending sebelum simpan
    if (_previousValue != null && _operation != null) {
      setState(() {
        _calculateInternal();
        _updateDisplay();
      });
    }

    final amount = double.tryParse(_amount.isEmpty ? '0' : _amount) ?? 0;
    if (amount <= 0) {
      AppToast.error(context, 'Masukkan nominal transaksi');
      return;
    }

    final provider = context.read<FinanceProvider>();
    final note = _noteController.text.trim();
    final transactionType = _selectedCategory!.type;

    if (_isEditing) {
      final transaction = TransactionModel(
        id: widget.transaction!.id,
        title: note.isEmpty ? _selectedCategory!.name : note,
        amount: amount,
        type: transactionType,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        categoryIcon: _selectedCategory!.icon,
        categoryColor: _selectedCategory!.color,
        accountId: _selectedAccount?.id,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
        createdAt: widget.transaction!.createdAt,
      );
      await provider.updateTransaction(transaction);
      if (mounted) {
        Navigator.pop(context);
        AppToast.success(context, 'Transaksi berhasil diperbarui');
      }
    } else {
      final transaction = TransactionModel(
        id: const Uuid().v4(),
        title: note.isEmpty ? _selectedCategory!.name : note,
        amount: amount,
        type: transactionType,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        categoryIcon: _selectedCategory!.icon,
        categoryColor: _selectedCategory!.color,
        accountId: _selectedAccount?.id,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
        createdAt: DateTime.now(),
      );
      await provider.addTransaction(transaction);
      if (mounted) {
        Navigator.pop(context);
        AppToast.success(context, 'Transaksi berhasil ditambahkan');
      }
    }
  }

  String _getFormattedAmount() {
    if (_previousValue != null && _operation != null) {
      return _displayAmount;
    }
    if (_amount.isEmpty || _amount == '0') return '0';
    final number = double.tryParse(_amount) ?? 0;
    if (number == number.truncateToDouble()) {
      return NumberFormat('#,###', 'id_ID')
          .format(number.toInt())
          .replaceAll(',', '.');
    }
    return NumberFormat('#,##0.##', 'id_ID')
        .format(number)
        .replaceAll(',', '.');
  }

  // ── BUILD ──

  @override
  Widget build(BuildContext context) {
    final isExpense = _selectedType == TransactionType.expense;
    final typeColor = isExpense ? AppTheme.expense : AppTheme.income;
    final hasOperation = _previousValue != null && _operation != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Type selector
          if (!_isEditing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTypeTab(
                      label: 'Pengeluaran',
                      type: TransactionType.expense,
                      activeColor: AppTheme.expense,
                    ),
                    _buildTypeTab(
                      label: 'Pemasukan',
                      type: TransactionType.income,
                      activeColor: AppTheme.income,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Account & Category
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showAccountPicker,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dari akun',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _selectedAccount != null
                                    ? Color(_selectedAccount!.color)
                                        .withValues(alpha: 0.2)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_selectedAccount?.icon ?? '💳',
                                  style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedAccount?.name ?? 'Pilih',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _showCategoryPicker,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ke kategori',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _selectedCategory != null
                                    ? Color(_selectedCategory!.color)
                                        .withValues(alpha: 0.2)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_selectedCategory?.icon ?? '📦',
                                  style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedCategory?.name ?? 'Pilih',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Amount display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Rp ${_getFormattedAmount()}',
              style: TextStyle(
                fontSize: hasOperation ? 30 : 44,
                fontWeight: FontWeight.w700,
                color: typeColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.calendar_today_outlined,
                  label: 'Tanggal',
                  onTap: _pickDate,
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.add_comment_outlined,
                  label: _noteController.text.trim().isEmpty
                      ? 'Catatan'
                      : 'Catatan ✓',
                  onTap: () => setState(
                      () => _isNoteEditorVisible = !_isNoteEditorVisible),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: _isNoteEditorVisible
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Tambahkan catatan...',
                        prefixIcon: const Icon(Icons.sticky_note_2_outlined),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => setState(() => _note = v),
                      onSubmitted: (_) =>
                          setState(() => _isNoteEditorVisible = false),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const Spacer(),

          // ── NUMPAD ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                _numRow([
                  _buildNumberButton('7', () => _onNumberPressed('7')),
                  _buildNumberButton('8', () => _onNumberPressed('8')),
                  _buildNumberButton('9', () => _onNumberPressed('9')),
                  _buildOperatorButton('÷', () => _onOperatorPressed('÷')),
                ]),
                const SizedBox(height: 8),
                _numRow([
                  _buildNumberButton('4', () => _onNumberPressed('4')),
                  _buildNumberButton('5', () => _onNumberPressed('5')),
                  _buildNumberButton('6', () => _onNumberPressed('6')),
                  _buildOperatorButton('×', () => _onOperatorPressed('×')),
                ]),
                const SizedBox(height: 8),
                _numRow([
                  _buildNumberButton('1', () => _onNumberPressed('1')),
                  _buildNumberButton('2', () => _onNumberPressed('2')),
                  _buildNumberButton('3', () => _onNumberPressed('3')),
                  _buildOperatorButton('-', () => _onOperatorPressed('-')),
                ]),
                const SizedBox(height: 8),
                _numRow([
                  _buildOperatorButton('C', _onClear),
                  _buildNumberButton('0', () => _onNumberPressed('0')),
                  _buildNumberButton('00', _onDoubleZeroPressed),
                  _buildOperatorButton('+', () => _onOperatorPressed('+')),
                ]),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildIconButton(
                          Icons.backspace_outlined, _onBackspace),
                    ),
                    const SizedBox(width: 8),
                    if (hasOperation) ...[
                      Expanded(
                        flex: 1,
                        child: _buildActionKeyButton(
                          label: '=',
                          color: Colors.orange.shade600,
                          onTap: _onEqualsPressed,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      flex: 2,
                      child: _buildSaveButton(typeColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── WIDGET HELPERS ──

  Widget _numRow(List<Widget> children) {
    final List<Widget> spaced = [];
    for (int i = 0; i < children.length; i++) {
      spaced.add(Expanded(child: children[i]));
      if (i < children.length - 1) spaced.add(const SizedBox(width: 8));
    }
    return Row(children: spaced);
  }

  Widget _buildTypeTab({
    required String label,
    required TransactionType type,
    required Color activeColor,
  }) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: label == '00' ? 20 : 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorButton(String label, VoidCallback onTap) {
    final isActive = _operation == label && _previousValue != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? Colors.orange.shade200 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.orange.shade400 : Colors.orange.shade200,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Icon(icon, color: Colors.grey.shade700, size: 24),
        ),
      ),
    );
  }

  Widget _buildActionKeyButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildSaveButton(Color color) {
    return GestureDetector(
      onTap: _onSave,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 6),
              Text(
                _isEditing ? 'Perbarui' : 'Simpan',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // ── PICKERS ──

  void _showCategoryPicker() {
    final provider = context.read<FinanceProvider>();
    final categories = _selectedType == TransactionType.expense
        ? provider.expenseCategories
        : provider.incomeCategories;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedType == TransactionType.expense
                  ? 'Kategori Pengeluaran'
                  : 'Kategori Pemasukan',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: categories.length,
                itemBuilder: (ctx, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategory?.id == category.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = category);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(category.color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Color(category.color)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(category.icon,
                              style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountPicker() {
    final provider = context.read<FinanceProvider>();
    final accounts = [...provider.regularAccounts, ...provider.savingsAccounts];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Pilih Akun',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: accounts.length,
                itemBuilder: (ctx, index) {
                  final account = accounts[index];
                  final isSelected = _selectedAccount?.id == account.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAccount = account);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(account.color).withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Color(account.color)
                              : AppTheme.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color:
                                  Color(account.color).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(account.icon,
                                  style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  Text(account.name,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary)),
                                  if (account.isPrimary) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.star,
                                        size: 14, color: Colors.amber),
                                  ],
                                ]),
                                if (isSelected)
                                  Icon(Icons.check_circle,
                                      color: Color(account.color), size: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Pilih Tanggal',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.today, color: Colors.blue.shade700),
              title: const Text('Hari ini',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(DateFormat('d MMMM yyyy', 'id_ID').format(now),
                  style: const TextStyle(fontSize: 12)),
              onTap: () {
                setState(() => _selectedDate = now);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.blue.shade700),
              title: const Text('Kemarin',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                  DateFormat('d MMMM yyyy', 'id_ID').format(yesterday),
                  style: const TextStyle(fontSize: 12)),
              onTap: () {
                setState(() => _selectedDate = yesterday);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_month, color: Colors.blue.shade700),
              title: const Text('Pilih hari',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle:
                  const Text('Buka kalender', style: TextStyle(fontSize: 12)),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme:
                          const ColorScheme.light(primary: AppTheme.accent),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
