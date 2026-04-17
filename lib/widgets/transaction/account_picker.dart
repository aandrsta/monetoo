// lib/widgets/transaction/account_picker.dart

import 'package:flutter/material.dart';
import '../../models/account_model.dart';
import '../../utils/app_colors.dart';

class AccountPicker extends StatelessWidget {
  final List<AccountModel> accounts;
  final AccountModel? selectedAccount;
  final Function(AccountModel) onSelected;

  const AccountPicker({
    super.key,
    required this.accounts,
    required this.selectedAccount,
    required this.onSelected,
  });

  static void show(
    BuildContext context, {
    required List<AccountModel> accounts,
    required AccountModel? selectedAccount,
    required Function(AccountModel) onSelected,
  }) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: c.modalBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: c.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Pilih Akun',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: accounts.length,
                itemBuilder: (ctx, i) {
                  final acc = accounts[i];
                  final isSel = selectedAccount?.id == acc.id;
                  return GestureDetector(
                    onTap: () {
                      onSelected(acc);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSel
                            ? Color(acc.color).withValues(alpha: 0.1)
                            : c.bgLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                isSel ? Color(acc.color) : Colors.transparent,
                            width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Text(acc.icon, style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(acc.name,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary)),
                          ),
                          if (acc.isPrimary)
                            const Icon(Icons.star, size: 14, color: Colors.amber),
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

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
