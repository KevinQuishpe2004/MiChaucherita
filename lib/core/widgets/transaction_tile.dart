import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

enum TransactionType { income, expense, transfer }

/// Tile de transacción para mostrar en listas
class TransactionTile extends StatelessWidget {
  final String title;
  final String category;
  final String amount;
  final String date;
  final TransactionType type;
  final IconData categoryIcon;
  final Color categoryColor;
  final VoidCallback? onTap;
  final int animationDelay;

  const TransactionTile({
    super.key,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    this.categoryIcon = Icons.category,
    this.categoryColor = AppColors.primary,
    this.onTap,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = type == TransactionType.income;
    final isTransfer = type == TransactionType.transfer;
    
    final amountColor = isTransfer 
        ? AppColors.transfer 
        : (isIncome ? AppColors.income : AppColors.expense);
    
    final amountPrefix = isTransfer ? '' : (isIncome ? '+' : '-');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.md,
          ),
          child: Row(
            children: [
              // Icono de categoría
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(
                  categoryIcon,
                  color: categoryColor,
                  size: AppSizes.iconMd,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppSizes.fontMd,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: AppSizes.fontXs,
                              fontWeight: FontWeight.w500,
                              color: categoryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: AppSizes.fontSm,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Monto
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amountPrefix$amount',
                    style: TextStyle(
                      fontSize: AppSizes.fontLg,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                  if (isTransfer) ...[
                    const SizedBox(height: AppSizes.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          size: AppSizes.iconXs,
                          color: AppColors.transfer,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Transferencia',
                          style: TextStyle(
                            fontSize: AppSizes.fontXs,
                            color: AppColors.transfer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }
}
