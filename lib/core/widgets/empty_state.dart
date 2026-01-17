import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Estado vacío para listas y páginas
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.primary,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            const SizedBox(height: AppSizes.lg),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppSizes.fontXl,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2, end: 0),
            if (subtitle != null) ...[
              const SizedBox(height: AppSizes.sm),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: AppSizes.fontMd,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSizes.lg),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.md,
                  ),
                ),
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}
