import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: c.divider,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
