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
  double? _previousValue;
  String? _operation;
  bool _shouldResetAmount = false;

  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  DateTime _selectedDate = DateTime.now();
  late final TextEditingController _noteController;

  TransactionType _selectedType = TransactionType.expense;

  bool get _isEditing => widget.transaction != null;

  // Warna latar akun & kategori — light theme
  static const Color _accountBg = Color(0xFFEEF2FF);
  static const Color _categoryBg = Color(0xFFF3EEFF);

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

  // ── KALKULASI ──

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
        _amount += '00';
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

  // ── SIMPAN ──

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

  // ── BUILD ──

  @override
  Widget build(BuildContext context) {
    final isExpense = _selectedType == TransactionType.expense;
    final typeColor = isExpense ? AppTheme.expense : AppTheme.income;
    final hasOp = _previousValue != null && _operation != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── TYPE SELECTOR (hanya saat tambah baru) ──
          if (!_isEditing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    _typeTab('Pengeluaran', TransactionType.expense,
                        AppTheme.expense),
                    _typeTab(
                        'Pemasukan', TransactionType.income, AppTheme.income),
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
                    onTap: _showAccountPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _accountBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dari akun',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Text(_selectedAccount?.icon ?? '💳',
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedAccount?.name ?? 'Pilih',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary),
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
                    onTap: _showCategoryPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _categoryBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ke kategori',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Text(_selectedCategory?.icon ?? '📦',
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedCategory?.name ?? 'Pilih',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary),
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

          // ── CATATAN + TANGGAL (pill row) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                // Pill tanggal
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          _isToday(_selectedDate)
                              ? 'Hari ini • ${DateFormat('HH:mm').format(_selectedDate)}'
                              : DateFormat('d MMM • HH:mm', 'id_ID')
                                  .format(_selectedDate),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Field catatan
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textPrimary),
                    maxLines: 1,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Tambah catatan...',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                      prefixIcon: Icon(
                        _noteController.text.trim().isNotEmpty
                            ? Icons.sticky_note_2_rounded
                            : Icons.edit_note_rounded,
                        size: 15,
                        color: AppTheme.textSecondary,
                      ),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 34, maxWidth: 34),
                      isDense: true,
                      filled: true,
                      fillColor: AppTheme.bgLight,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: typeColor.withValues(alpha: 0.5),
                              width: 1.5)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 60),
          const Divider(height: 1, color: AppTheme.divider),

          // ── NUMPAD ──
          _buildNumpad(typeColor, hasOp),
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

  // ── NUMPAD WIDGET ──
  // Layout kolom: [op(52) | gap | angka(Expanded) | gap | kanan(64)]
  // Kolom kanan:  [backspace(1 baris)] + [simpan(3 baris)]

  Widget _buildNumpad(Color typeColor, bool hasOp) {
    const h = 56.0;
    const gap = 8.0;
    const double sideW = 64.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── KOLOM KIRI: 4 operator ──
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _opKey('÷', h),
                const SizedBox(height: gap),
                _opKey('×', h),
                const SizedBox(height: gap),
                _opKey('−', h),
                const SizedBox(height: gap),
                _opKey('+', h),
              ],
            ),
            const SizedBox(width: gap),

            // ── KOLOM TENGAH: 4 baris angka ──
            Expanded(
              child: Column(
                children: [
                  Row(children: [
                    Expanded(child: _numKeyFull('7', h)),
                    const SizedBox(width: gap),
                    Expanded(child: _numKeyFull('8', h)),
                    const SizedBox(width: gap),
                    Expanded(child: _numKeyFull('9', h)),
                  ]),
                  const SizedBox(height: gap),
                  Row(children: [
                    Expanded(child: _numKeyFull('4', h)),
                    const SizedBox(width: gap),
                    Expanded(child: _numKeyFull('5', h)),
                    const SizedBox(width: gap),
                    Expanded(child: _numKeyFull('6', h)),
                  ]),
                  const SizedBox(height: gap),
                  Row(children: [
                    Expanded(child: _numKeyFull('1', h)),
                    const SizedBox(width: gap),
                    Expanded(child: _numKeyFull('2', h)),
                    const SizedBox(width: gap),
                    Expanded(child: _numKeyFull('3', h)),
                  ]),
                  const SizedBox(height: gap),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _onClear,
                        child: Container(
                          height: h,
                          decoration: BoxDecoration(
                            color: AppTheme.bgLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text('C',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(child: _numKeyFull('0', h)),
                    const SizedBox(width: gap),
                    Expanded(
                      child: GestureDetector(
                        onTap: _onDoubleZero,
                        child: Container(
                          height: h,
                          decoration: BoxDecoration(
                            color: AppTheme.bgLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text('00',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: gap),

            // ── KOLOM KANAN: backspace (baris 1) + simpan (baris 2–4) ──
            SizedBox(
              width: sideW,
              child: Column(
                children: [
                  // Backspace — 1 baris
                  SizedBox(
                    height: h,
                    child: GestureDetector(
                      onTap: _onBackspace,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.bgLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(Icons.backspace_outlined,
                              color: AppTheme.textSecondary, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: gap),
                  // Simpan — mengisi sisa 3 baris + 2 gap
                  Expanded(
                    child: hasOp
                        ? Column(children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _onEquals,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade500,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: Text('=',
                                        style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: gap),
                            Expanded(child: _saveButton(typeColor)),
                          ])
                        : _saveButton(typeColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── KEY BUILDERS ──

  Widget _numKeyFull(String label, double h) {
    return GestureDetector(
      onTap: () => _onNumber(label),
      child: Container(
        height: h,
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary)),
        ),
      ),
    );
  }

  Widget _opKey(String op, double h) {
    final isActive = _operation == op && _previousValue != null;
    return SizedBox(
      width: 52,
      height: h,
      child: GestureDetector(
        onTap: () => _onOperator(op),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.orange.shade500
                : Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(op,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.white : Colors.orange.shade600)),
          ),
        ),
      ),
    );
  }

  Widget _saveButton(Color color) {
    return GestureDetector(
      onTap: _onSave,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Icon(
            _isEditing ? Icons.check_rounded : Icons.check_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _typeTab(String label, TransactionType type, Color color) {
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
                    color: isSel ? Colors.white : AppTheme.textSecondary)),
          ),
        ),
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
                        color: Color(cat.color).withValues(alpha: 0.12),
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
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSel
                            ? Color(acc.color).withValues(alpha: 0.1)
                            : AppTheme.bgLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                isSel ? Color(acc.color) : Colors.transparent,
                            width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Text(acc.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(acc.name,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                          ),
                          if (acc.isPrimary)
                            const Icon(Icons.star,
                                size: 14, color: Colors.amber),
                          if (isSel) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.check_circle,
                                color: Color(acc.color), size: 20),
                          ],
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
                    color: AppTheme.divider,
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
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
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
                      colorScheme:
                          const ColorScheme.light(primary: AppTheme.accent)),
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
    return ListTile(
      leading: Icon(icon, color: AppTheme.accent),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      onTap: onTap,
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
