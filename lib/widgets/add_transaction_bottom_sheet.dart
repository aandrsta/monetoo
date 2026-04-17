// lib/widgets/add_transaction_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/account_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../utils/app_toast.dart';
import '../widgets/calculator_numpad.dart';
import 'transaction/account_picker.dart';
import 'transaction/category_picker.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  final CategoryModel? initialCategory;
  final TransactionModel? transaction;

  const AddTransactionBottomSheet({
    super.key,
    this.initialCategory,
    this.transaction,
  });

  static void show(BuildContext context,
      {TransactionModel? transaction, CategoryModel? initialCategory}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionBottomSheet(
        transaction: transaction,
        initialCategory: initialCategory,
      ),
    );
  }

  @override
  State<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  String _amount = '0';
  double? _previousValue;
  String? _operation;
  bool _shouldResetAmount = false;

  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  DateTime _selectedDate = DateTime.now();
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
              _selectedAccount = accounts.firstWhere((a) => a.isPrimary,
                  orElse: () => accounts.first);
            }
          } else {
            _selectedAccount = accounts.firstWhere((a) => a.isPrimary,
                orElse: () => accounts.first);
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
          if (accounts.isNotEmpty) {
            _selectedAccount = accounts.firstWhere((a) => a.isPrimary,
                orElse: () => accounts.first);
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

  void _onNumber(String n) {
    setState(() {
      if (_shouldResetAmount) {
        _amount = n;
        _shouldResetAmount = false;
      } else if (_amount == '0') {
        _amount = n;
      } else if (_amount.length < 15) {
        _amount += n;
      }
    });
  }

  void _onDoubleZero() {
    setState(() {
      if (_shouldResetAmount) {
        _amount = '0';
        _shouldResetAmount = false;
      } else if (_amount != '0' && _amount.length < 14) {
        _amount += '000';
      }
    });
  }

  void _onOperator(String op) {
    setState(() {
      if (_previousValue != null && _operation != null && !_shouldResetAmount) {
        _calcInternal();
      }
      _previousValue = double.tryParse(_amount) ?? 0;
      _operation = op;
      _shouldResetAmount = true;
    });
  }

  void _calcInternal() {
    if (_previousValue == null || _operation == null) return;
    final cur = double.tryParse(_amount) ?? 0;
    double res = _previousValue!;
    switch (_operation) {
      case '+':
        res = _previousValue! + cur;
        break;
      case '−':
        res = _previousValue! - cur;
        break;
      case '×':
        res = _previousValue! * cur;
        break;
      case '÷':
        if (cur != 0) res = _previousValue! / cur;
        break;
    }
    if (res == res.truncateToDouble()) {
      _amount = res.toInt().toString();
    } else {
      _amount = res.toStringAsFixed(0);
    }
    _previousValue = null;
    _operation = null;
    _shouldResetAmount = false;
  }

  void _onEquals() {
    if (_previousValue == null || _operation == null) return;
    setState(_calcInternal);
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
    });
  }

  void _onClear() {
    setState(() {
      _amount = '0';
      _previousValue = null;
      _operation = null;
      _shouldResetAmount = false;
    });
  }

  String _formatted() {
    final n = double.tryParse(_amount) ?? 0;
    return NumberFormat('#,###', 'id_ID')
        .format(n.toInt())
        .replaceAll(',', '.');
  }

  void _onSave() async {
    if (_selectedCategory == null) {
      AppToast.error(context, 'Pilih kategori terlebih dahulu');
      return;
    }
    if (_previousValue != null && _operation != null) {
      setState(_calcInternal);
    }
    final amount = double.tryParse(_amount) ?? 0;
    if (amount <= 0) {
      AppToast.error(context, 'Masukkan nominal transaksi');
      return;
    }

    final provider = context.read<FinanceProvider>();
    final note = _noteController.text.trim();

    if (_isEditing) {
      await provider.updateTransaction(TransactionModel(
        id: widget.transaction!.id,
        title: note.isEmpty ? _selectedCategory!.name : note,
        amount: amount,
        type: _selectedCategory!.type,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        categoryIcon: _selectedCategory!.icon,
        categoryColor: _selectedCategory!.color,
        accountId: _selectedAccount?.id,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
        createdAt: widget.transaction!.createdAt,
      ));
      if (mounted) {
        Navigator.pop(context);
        AppToast.success(context, 'Transaksi berhasil diperbarui');
      }
    } else {
      await provider.addTransaction(TransactionModel(
        id: const Uuid().v4(),
        title: note.isEmpty ? _selectedCategory!.name : note,
        amount: amount,
        type: _selectedCategory!.type,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        categoryIcon: _selectedCategory!.icon,
        categoryColor: _selectedCategory!.color,
        accountId: _selectedAccount?.id,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
        createdAt: DateTime.now(),
      ));
      if (mounted) {
        Navigator.pop(context);
        AppToast.success(context, 'Transaksi berhasil ditambahkan');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isExpense = _selectedType == TransactionType.expense;
    final typeColor = isExpense ? c.expense : c.income;
    final hasOp = _previousValue != null && _operation != null;

    // Warna background pill akun & kategori — sedikit berbeda per type
    final accountBg = c.accent.withValues(alpha: 0.08);
    final categoryBg = typeColor.withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        color: c.modalBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            decoration: BoxDecoration(
              color: c.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── TYPE SELECTOR ──
          if (!_isEditing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                    color: c.bgLight, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    _typeTab('Pengeluaran', TransactionType.expense, c.expense),
                    _typeTab('Pemasukan', TransactionType.income, c.income),
                  ],
                ),
              ),
            ),

          // ── AKUN & KATEGORI ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => AccountPicker.show(
                      context,
                      accounts: context.read<FinanceProvider>().accounts,
                      selectedAccount: _selectedAccount,
                      onSelected: (acc) => setState(() => _selectedAccount = acc),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: accountBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dari akun',
                              style: TextStyle(
                                  fontSize: 11, color: c.textSecondary)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Text(_selectedAccount?.icon ?? '💳',
                                style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedAccount?.name ?? 'Pilih',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final provider = context.read<FinanceProvider>();
                      CategoryPicker.show(
                        context,
                        categories: _selectedType == TransactionType.expense
                            ? provider.expenseCategories
                            : provider.incomeCategories,
                        selectedCategory: _selectedCategory,
                        type: _selectedType,
                        onSelected: (cat) => setState(() => _selectedCategory = cat),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: categoryBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ke kategori',
                              style: TextStyle(
                                  fontSize: 11, color: c.textSecondary)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Text(_selectedCategory?.icon ?? '📦',
                                style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedCategory?.name ?? 'Pilih',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── NOMINAL ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Rp ',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: typeColor.withValues(alpha: 0.7))),
                Expanded(
                  child: Text(
                    hasOp
                        ? '${_fmtPrev(_previousValue!)} $_operation ${_shouldResetAmount ? '0' : _formatted()}'
                        : _formatted(),
                    style: TextStyle(
                        fontSize: hasOp ? 26 : 40,
                        fontWeight: FontWeight.w700,
                        color: typeColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // ── TANGGAL + CATATAN ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.bgLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 13, color: c.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          _isToday(_selectedDate)
                              ? 'Hari ini • ${DateFormat('HH:mm').format(_selectedDate)}'
                              : DateFormat('d MMM • HH:mm', 'id_ID')
                                  .format(_selectedDate),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _showNoteDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _noteController.text.trim().isNotEmpty
                            ? c.income.withValues(alpha: 0.08)
                            : c.bgLight,
                        borderRadius: BorderRadius.circular(10),
                        border: _noteController.text.trim().isNotEmpty
                            ? Border.all(
                                color: c.income.withValues(alpha: 0.25))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _noteController.text.trim().isNotEmpty
                                ? Icons.sticky_note_2_rounded
                                : Icons.edit_note_rounded,
                            size: 14,
                            color: _noteController.text.trim().isNotEmpty
                                ? c.income
                                : c.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _noteController.text.trim().isNotEmpty
                                  ? _noteController.text.trim()
                                  : 'Tambah catatan...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _noteController.text.trim().isNotEmpty
                                    ? c.textPrimary
                                    : c.textSecondary,
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

          const SizedBox(height: 10),
          Divider(height: 1, color: c.divider),

          // ── NUMPAD ──
          CalculatorNumpad(
            typeColor: typeColor,
            hasOperation: hasOp,
            selectedOperator: _operation,
            onNumber: _onNumber,
            onDoubleZero: _onDoubleZero,
            onClear: _onClear,
            onBackspace: _onBackspace,
            onOperator: _onOperator,
            onEquals: _onEquals,
            onSave: _onSave,
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _fmtPrev(double n) {
    return NumberFormat('#,###', 'id_ID')
        .format(n.toInt())
        .replaceAll(',', '.');
  }


  Widget _typeTab(String label, TransactionType type, Color color) {
    final c = context.colors;
    final isSel = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedType == type) return;
          setState(() {
            _selectedType = type;
            if (_selectedCategory != null && _selectedCategory!.type != type) {
              _selectedCategory = null;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSel
                ? [
                    BoxShadow(
                        color: color.withValues(alpha: 0.3),
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
                    color: isSel ? c.cardBg : c.textSecondary)),
          ),
        ),
      ),
    );
  }

  Future<void> _showNoteDialog() async {
    final c = context.colors;
    final tempCtrl = TextEditingController(text: _noteController.text);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: c.modalBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: c.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Catatan',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary)),
              const SizedBox(height: 12),
              TextField(
                controller: tempCtrl,
                autofocus: true,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.done,
                style: TextStyle(fontSize: 14, color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Tulis catatan...',
                  hintStyle: TextStyle(fontSize: 14, color: c.textSecondary),
                  filled: true,
                  fillColor: c.bgLight,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.accent, width: 1.5)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onSubmitted: (_) => Navigator.pop(ctx),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      tempCtrl.clear();
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                          color: c.bgLight,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text('Hapus catatan',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.textSecondary)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                          color: c.accent,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text('Simpan',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: c.cardBg)),
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (mounted) {
      setState(() => _noteController.text = tempCtrl.text.trim());
    }
    tempCtrl.dispose();
  }

  }

  Future<void> _pickDate() async {
    final c = context.colors;
    final now = DateTime.now();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: c.modalBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: c.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Pilih Tanggal',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary)),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID')
                  .format(_selectedDate),
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
            const SizedBox(height: 8),
            _dateTile(
                ctx,
                'Hari ini',
                DateFormat('d MMMM yyyy', 'id_ID').format(now),
                Icons.today, () {
              setState(() => _selectedDate = DateTime.now());
              Navigator.pop(ctx);
            }),
            _dateTile(
                ctx,
                'Kemarin',
                DateFormat('d MMMM yyyy', 'id_ID')
                    .format(now.subtract(const Duration(days: 1))),
                Icons.history, () {
              setState(
                  () => _selectedDate = now.subtract(const Duration(days: 1)));
              Navigator.pop(ctx);
            }),
            _dateTile(ctx, 'Pilih tanggal lain', 'Buka kalender',
                Icons.calendar_month, () async {
              Navigator.pop(ctx);
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(primary: c.accent)),
                  child: child!,
                ),
              );
              if (picked != null && mounted) {
                setState(() => _selectedDate = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      _selectedDate.hour,
                      _selectedDate.minute,
                    ));
              }
            }),
            _dateTile(
                ctx,
                'Ubah waktu',
                DateFormat('HH:mm').format(_selectedDate),
                Icons.access_time_rounded, () {
              Navigator.pop(ctx);
              _pickTime();
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _dateTile(BuildContext ctx, String title, String subtitle,
      IconData icon, VoidCallback onTap) {
    final c = context.colors;
    return ListTile(
      leading: Icon(icon, color: c.accent),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w500, color: c.textPrimary)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: c.textSecondary)),
      onTap: onTap,
    );
  }

  Future<void> _pickTime() async {
    final c = context.colors;
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: _selectedDate.hour, minute: _selectedDate.minute),
      builder: (context, child) => Theme(
        data: Theme.of(context)
            .copyWith(colorScheme: ColorScheme.light(primary: c.accent)),
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
