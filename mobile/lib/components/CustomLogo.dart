import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';

class CustomLogo extends StatelessWidget {
  const CustomLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 90,
        height: 90,

        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,

          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            width: 2,
          ),
        ),

        child: const Icon(
          Icons.psychology_rounded,
          size: 50,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }
}
