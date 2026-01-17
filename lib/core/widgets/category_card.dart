import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Tarjeta de categoría
class CategoryCard extends StatelessWidget {
  final String name;
  final String amount;
  final IconData icon;
  final Color color;
  final bool isExpense;
  final double? percentage;
  final VoidCallback? onTap;
  final int animationDelay;

  const CategoryCard({
    super.key,
    required this.name,
    required this.amount,
    required this.icon,
    required this.color,
    this.isExpense = true,
    this.percentage,
    this.onTap,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
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
                    name,
                    style: const TextStyle(
                      fontSize: AppSizes.fontMd,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (percentage != null) ...[
                    const SizedBox(height: AppSizes.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      child: LinearProgressIndicator(
                        value: percentage! / 100,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isExpense ? '-$amount' : '+$amount',
                  style: TextStyle(
                    fontSize: AppSizes.fontLg,
                    fontWeight: FontWeight.bold,
                    color: isExpense ? AppColors.expense : AppColors.income,
                  ),
                ),
                if (percentage != null) ...[
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    '${percentage!.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSm,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.05, end: 0);
  }
}
