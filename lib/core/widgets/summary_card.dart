import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Tarjeta de resumen de ingresos/egresos
class SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final bool isIncome;
  final VoidCallback? onTap;
  final int animationDelay;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.isIncome = true,
    this.onTap,
    this.animationDelay = 0,
  });

  factory SummaryCard.income({
    required String amount,
    VoidCallback? onTap,
    int animationDelay = 0,
  }) {
    return SummaryCard(
      title: 'Ingresos',
      amount: amount,
      icon: Icons.arrow_downward_rounded,
      color: AppColors.income,
      backgroundColor: AppColors.incomeLight,
      isIncome: true,
      onTap: onTap,
      animationDelay: animationDelay,
    );
  }

  factory SummaryCard.expense({
    required String amount,
    VoidCallback? onTap,
    int animationDelay = 0,
  }) {
    return SummaryCard(
      title: 'Gastos',
      amount: amount,
      icon: Icons.arrow_upward_rounded,
      color: AppColors.expense,
      backgroundColor: AppColors.expenseLight,
      isIncome: false,
      onTap: onTap,
      animationDelay: animationDelay,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(
                icon,
                color: color,
                size: AppSizes.iconMd,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    amount,
                    style: TextStyle(
                      color: color,
                      fontSize: AppSizes.fontXl,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 400.ms)
        .slideX(begin: isIncome ? -0.1 : 0.1, end: 0);
  }
}
