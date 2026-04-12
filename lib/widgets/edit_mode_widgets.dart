import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class EditModeButton extends StatelessWidget {
  final bool isEditMode;
  final VoidCallback onTap;

  const EditModeButton({
    super.key,
    required this.isEditMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isEditMode ? c.accent : c.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isEditMode ? Icons.edit_rounded : Icons.edit_outlined,
          color: isEditMode ? c.cardBg : c.accent,
          size: 20,
        ),
      ),
    );
  }
}

class EditModeBanner extends StatelessWidget {
  final String message;

  const EditModeBanner({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: c.accent.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
