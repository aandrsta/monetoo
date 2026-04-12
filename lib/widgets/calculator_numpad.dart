// lib/widgets/calculator_numpad.dart

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CalculatorNumpad extends StatelessWidget {
  final Color typeColor;
  final bool hasOperation;
  final String? selectedOperator;
  final Function(String) onNumber;
  final VoidCallback onDoubleZero;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final Function(String) onOperator;
  final VoidCallback onEquals;
  final VoidCallback onSave;

  const CalculatorNumpad({
    super.key,
    required this.typeColor,
    required this.hasOperation,
    this.selectedOperator,
    required this.onNumber,
    required this.onDoubleZero,
    required this.onClear,
    required this.onBackspace,
    required this.onOperator,
    required this.onEquals,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const h = 56.0;
    const gap = 8.0;
    const double sideW = 64.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _opKey('÷', h, c),
                const SizedBox(height: gap),
                _opKey('×', h, c),
                const SizedBox(height: gap),
                _opKey('−', h, c),
                const SizedBox(height: gap),
                _opKey('+', h, c),
              ],
            ),
            const SizedBox(width: gap),
            Expanded(
              child: Column(
                children: [
                  Row(children: [
                    Expanded(child: _numKey('7', h, c)),
                    const SizedBox(width: gap),
                    Expanded(child: _numKey('8', h, c)),
                    const SizedBox(width: gap),
                    Expanded(child: _numKey('9', h, c)),
                  ]),
                  const SizedBox(height: gap),
                  Row(children: [
                    Expanded(child: _numKey('4', h, c)),
                    const SizedBox(width: gap),
                    Expanded(child: _numKey('5', h, c)),
                    const SizedBox(width: gap),
                    Expanded(child: _numKey('6', h, c)),
                  ]),
                  const SizedBox(height: gap),
                  Row(children: [
                    Expanded(child: _numKey('1', h, c)),
                    const SizedBox(width: gap),
                    Expanded(child: _numKey('2', h, c)),
                    const SizedBox(width: gap),
                    Expanded(child: _numKey('3', h, c)),
                  ]),
                  const SizedBox(height: gap),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onClear,
                        child: Container(
                          height: h,
                          decoration: BoxDecoration(
                            color: c.bgLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text('C',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: c.textSecondary)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(child: _numKey('0', h, c)),
                    const SizedBox(width: gap),
                    Expanded(
                      child: GestureDetector(
                        onTap: onDoubleZero,
                        child: Container(
                          height: h,
                          decoration: BoxDecoration(
                            color: c.bgLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text('000',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary)),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: gap),
            SizedBox(
              width: sideW,
              child: Column(
                children: [
                  SizedBox(
                    height: h,
                    child: GestureDetector(
                      onTap: onBackspace,
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.bgLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Icon(Icons.backspace_outlined,
                              color: c.textSecondary, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: gap),
                  Expanded(
                    child: hasOperation
                        ? Column(children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: onEquals,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade500,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text('=',
                                        style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: c.cardBg)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: gap),
                            Expanded(child: _saveButton(c)),
                          ])
                        : _saveButton(c),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numKey(String label, double h, AppColors c) {
    return GestureDetector(
      onTap: () => onNumber(label),
      child: Container(
        height: h,
        decoration: BoxDecoration(
          color: c.bgLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary)),
        ),
      ),
    );
  }

  Widget _opKey(String op, double h, AppColors c) {
    final isActive = selectedOperator == op;
    return SizedBox(
      width: 52,
      height: h,
      child: GestureDetector(
        onTap: () => onOperator(op),
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
                    color: isActive ? c.cardBg : Colors.orange.shade600)),
          ),
        ),
      ),
    );
  }

  Widget _saveButton(AppColors c) {
    return GestureDetector(
      onTap: onSave,
      child: Container(
        decoration: BoxDecoration(
          color: typeColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Icon(Icons.check_rounded, color: c.cardBg, size: 28),
        ),
      ),
    );
  }
}
