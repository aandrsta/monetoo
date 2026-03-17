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
  bool _isNoteExpanded = false;
  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  DateTime _selectedDate = DateTime.now();
  late final TextEditingController _noteController;
  late final FocusNode _noteFocusNode;

  TransactionType _selectedType = TransactionType.expense;

  bool get _isEditing => widget.transaction != null;

  bool get _isDateModified {
    final now = DateTime.now();
    return !(_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day);
  }

  @override
  void initState() {
    super.initState();
    _noteFocusNode = FocusNode();
    _noteController = TextEditingController();
    if (_isEditing) {
      final t = widget.transaction!;
      _amount = t.amount.toStringAsFixed(0);
      _displayAmount = _amount;
      _selectedDate = t.date;
      _noteController.text = t.note ?? '';
      _selectedType = t.type;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<FinanceProvider>();
        final categories = [
          ...provider.expenseCategories,
          ...provider.incomeCategories,
        ];
        setState(() {
          _selectedCategory = categories.firstWhere(
            (cat) => cat.id == t.categoryId,
            orElse: () => categories.first,
          );
          final accounts = provider.accounts;
          if (accounts.isEmpty) {
            _selectedAccount = null;
          } else if (t.accountId != null) {
            try {
              _selectedAccount =
                  accounts.firstWhere((a) => a.id == t.accountId);
            } catch (_) {
              try {
                _selectedAccount = accounts.firstWhere((a) => a.isPrimary);
              } catch (_) {
                _selectedAccount = accounts.first;
              }
            }
          } else {
            try {
              _selectedAccount = accounts.firstWhere((a) => a.isPrimary);
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<FinanceProvider>();
        final accounts = provider.accounts;
        setState(() {
          if (accounts.isEmpty) {
            _selectedAccount = null;
          } else {
            try {
              _selectedAccount = accounts.firstWhere((a) => a.isPrimary);
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
    _noteFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Saat keyboard dismiss (viewInsets.bottom turun ke 0), collapse note field
    final inset = MediaQuery.of(context).viewInsets.bottom;
    if (inset == 0 && _isNoteExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isNoteExpanded = false);
      });
    }
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
      final firstNum = _fmt(_previousValue!);
      final secondNum =
          _shouldResetAmount ? '0' : _fmt(double.tryParse(_amount) ?? 0);
      _displayAmount = '$firstNum $_operation $secondNum';
    } else {
      _displayAmount = _amount;
    }
  }

  String _fmt(double n) {
    if (n == n.truncateToDouble()) {
      return NumberFormat('#,###', 'id_ID')
          .format(n.toInt())
          .replaceAll(',', '.');
    }
    return NumberFormat('#,##0.##', 'id_ID').format(n).replaceAll(',', '.');
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

  void _onSave() async {
    if (_selectedCategory == null) {
      AppToast.error(context, 'Pilih kategori terlebih dahulu');
      return;
    }
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

  @override
  Widget build(BuildContext context) {
    final isExpense = _selectedType == TransactionType.expense;
    final typeColor = isExpense ? AppTheme.expense : AppTheme.income;
    final hasOperation = _previousValue != null && _operation != null;
    final hasNote = _noteController.text.trim().isNotEmpty;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Tinggi numpad fixed: 5 baris x 52 + 4 gap x 8 + padding 10+12
    const double numpadHeight = 5 * 52 + 4 * 8 + 10 + 12;

    return Container(
      // Cukup tinggi untuk konten + numpad, naik otomatis saat keyboard muncul
      height: MediaQuery.of(context).size.height * 0.88 + bottomInset,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),

          // Type selector
          if (!_isEditing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    _buildTypeTab(
                        label: 'Pengeluaran',
                        type: TransactionType.expense,
                        activeColor: AppTheme.expense),
                    _buildTypeTab(
                        label: 'Pemasukan',
                        type: TransactionType.income,
                        activeColor: AppTheme.income),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Account & Category row
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
                                fontSize: 11, color: Colors.grey.shade500)),
                        const SizedBox(height: 6),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _selectedAccount != null
                                  ? Color(_selectedAccount!.color)
                                      .withValues(alpha: 0.2)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_selectedAccount?.icon ?? '💳',
                                style: const TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedAccount?.name ?? 'Pilih',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
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
                                fontSize: 11, color: Colors.grey.shade500)),
                        const SizedBox(height: 6),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _selectedCategory != null
                                  ? Color(_selectedCategory!.color)
                                      .withValues(alpha: 0.2)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_selectedCategory?.icon ?? '📦',
                                style: const TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedCategory?.name ?? 'Pilih',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Amount display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Rp ${_getFormattedAmount()}',
              style: TextStyle(
                  fontSize: hasOperation ? 28 : 40,
                  fontWeight: FontWeight.w700,
                  color: typeColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),

          // Info bar: tanggal + catatan pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _isDateModified
                          ? AppTheme.accent.withValues(alpha: 0.08)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: _isDateModified
                          ? Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.3))
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 13,
                            color: _isDateModified
                                ? AppTheme.accent
                                : Colors.grey.shade500),
                        const SizedBox(width: 5),
                        Text(
                          _isDateModified
                              ? DateFormat('d MMM • HH:mm', 'id_ID')
                                  .format(_selectedDate)
                              : 'Hari ini • ${DateFormat('HH:mm').format(_selectedDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _isDateModified
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: _isDateModified
                                ? AppTheme.accent
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _isNoteExpanded = !_isNoteExpanded);
                      if (!_isNoteExpanded) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: hasNote
                            ? AppTheme.income.withValues(alpha: 0.08)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: hasNote
                            ? Border.all(
                                color: AppTheme.income.withValues(alpha: 0.25))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasNote
                                ? Icons.sticky_note_2_rounded
                                : Icons.add_comment_outlined,
                            size: 13,
                            color: hasNote
                                ? AppTheme.income
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              hasNote
                                  ? _noteController.text.trim()
                                  : 'Tambah catatan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    hasNote ? FontWeight.w500 : FontWeight.w400,
                                color: hasNote
                                    ? AppTheme.textPrimary
                                    : Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Note field — expand di antara pill dan divider
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _isNoteExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 3,
                      minLines: 1,
                      autofocus: true,
                      focusNode: _noteFocusNode,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Tulis catatan...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppTheme.accent, width: 1.5)),
                      ),
                      onChanged: (v) => setState(() {}),
                      onSubmitted: (_) =>
                          setState(() => _isNoteExpanded = false),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          _isNoteExpanded ? const SizedBox.shrink() : const Spacer(),
          const Divider(height: 1, color: AppTheme.divider),

          // Numpad — fixed di bawah, tinggi tetap
          SizedBox(
            height: numpadHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _numRow([
                    _numBtn('7', () => _onNumberPressed('7')),
                    _numBtn('8', () => _onNumberPressed('8')),
                    _numBtn('9', () => _onNumberPressed('9')),
                    _opBtn('÷', () => _onOperatorPressed('÷')),
                  ]),
                  _numRow([
                    _numBtn('4', () => _onNumberPressed('4')),
                    _numBtn('5', () => _onNumberPressed('5')),
                    _numBtn('6', () => _onNumberPressed('6')),
                    _opBtn('×', () => _onOperatorPressed('×')),
                  ]),
                  _numRow([
                    _numBtn('1', () => _onNumberPressed('1')),
                    _numBtn('2', () => _onNumberPressed('2')),
                    _numBtn('3', () => _onNumberPressed('3')),
                    _opBtn('-', () => _onOperatorPressed('-')),
                  ]),
                  _numRow([
                    _opBtn('C', _onClear),
                    _numBtn('0', () => _onNumberPressed('0')),
                    _numBtn('00', _onDoubleZeroPressed),
                    _opBtn('+', () => _onOperatorPressed('+')),
                  ]),
                  Row(
                    children: [
                      Expanded(
                          flex: 1,
                          child:
                              _iconBtn(Icons.backspace_outlined, _onBackspace)),
                      const SizedBox(width: 8),
                      if (hasOperation) ...[
                        Expanded(
                          flex: 1,
                          child: _actionBtn(
                              label: '=',
                              color: Colors.orange.shade600,
                              onTap: _onEqualsPressed),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(flex: 2, child: _saveBtn(typeColor)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numRow(List<Widget> children) {
    final List<Widget> spaced = [];
    for (int i = 0; i < children.length; i++) {
      spaced.add(Expanded(child: children[i]));
      if (i < children.length - 1) spaced.add(const SizedBox(width: 8));
    }
    return Row(children: spaced);
  }

  Widget _numBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: label == '00' ? 18 : 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800)),
        ),
      ),
    );
  }

  Widget _opBtn(String label, VoidCallback onTap) {
    final isActive = _operation == label && _previousValue != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isActive ? Colors.orange.shade200 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  isActive ? Colors.orange.shade400 : Colors.orange.shade200),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700)),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: Center(child: Icon(icon, color: Colors.grey.shade700, size: 22)),
      ),
    );
  }

  Widget _actionBtn(
      {required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
      ),
    );
  }

  Widget _saveBtn(Color color) {
    return GestureDetector(
      onTap: _onSave,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded, color: Colors.white, size: 20),
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

  Widget _buildTypeTab(
      {required String label,
      required TransactionType type,
      required Color activeColor}) {
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
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade500)),
          ),
        ),
      ),
    );
  }

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
                    borderRadius: BorderRadius.circular(2))),
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
                itemBuilder: (ctx, i) {
                  final cat = categories[i];
                  final isSel = _selectedCategory?.id == cat.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(cat.color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color:
                                isSel ? Color(cat.color) : Colors.transparent,
                            width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat.icon, style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(cat.name,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
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
    final accounts = provider.accounts;

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
                    borderRadius: BorderRadius.circular(2))),
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
                itemBuilder: (ctx, i) {
                  final acc = accounts[i];
                  final isSel = _selectedAccount?.id == acc.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAccount = acc);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSel
                            ? Color(acc.color).withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isSel ? Color(acc.color) : AppTheme.divider,
                            width: isSel ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                                color: Color(acc.color).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12)),
                            child: Center(
                                child: Text(acc.icon,
                                    style: const TextStyle(fontSize: 24))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  Text(acc.name,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary)),
                                  if (acc.isPrimary) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.star,
                                        size: 14, color: Colors.amber),
                                  ],
                                ]),
                                if (isSel)
                                  Icon(Icons.check_circle,
                                      color: Color(acc.color), size: 20),
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
    final yesterday =
        DateTime(now.year, now.month, now.day - 1, now.hour, now.minute);

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
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Pilih Tanggal',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID')
                  .format(_selectedDate),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.today, color: Colors.blue.shade700),
              title: const Text('Hari ini',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(DateFormat('d MMMM yyyy', 'id_ID').format(now),
                  style: const TextStyle(fontSize: 12)),
              onTap: () {
                setState(() => _selectedDate = DateTime.now());
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
              title: const Text('Pilih tanggal lain',
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
                            const ColorScheme.light(primary: AppTheme.accent)),
                    child: child!,
                  ),
                );
                if (picked != null && mounted) {
                  final now2 = DateTime.now();
                  setState(() => _selectedDate = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        now2.hour,
                        now2.minute,
                      ));
                  _pickTime();
                }
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.access_time_rounded, color: Colors.blue.shade700),
              title: const Text('Ubah waktu',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(DateFormat('HH:mm').format(_selectedDate),
                  style: const TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _pickTime();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: _selectedDate.hour, minute: _selectedDate.minute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.accent)),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }
}
