import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

/// Acciones rápidas para agregar transacciones
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: Iconsax.arrow_down,
              label: 'Ingreso',
              color: AppColors.income,
              onTap: () => context.push('/add-transaction?type=income'),
            ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2, end: 0),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: _QuickActionButton(
              icon: Iconsax.arrow_up_1,
              label: 'Egreso',
              color: AppColors.expense,
              onTap: () => context.push('/add-transaction?type=expense'),
            ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.2, end: 0),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: _QuickActionButton(
              icon: Iconsax.arrow_swap_horizontal,
              label: 'Transferir',
              color: AppColors.transfer,
              onTap: () => context.push('/add-transaction?type=transfer'),
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.md,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.xs),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: AppSizes.iconSm,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
