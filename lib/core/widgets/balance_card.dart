import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Tarjeta de balance principal con gradiente naranja
class BalanceCard extends StatelessWidget {
  final String title;
  final String balance;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final List<Color>? gradientColors;

  const BalanceCard({
    super.key,
    required this.title,
    required this.balance,
    this.subtitle,
    this.icon,
    this.onTap,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors ?? [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          boxShadow: [
            BoxShadow(
              color: (gradientColors?.first ?? AppColors.primary).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSizes.sm),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: AppSizes.iconMd,
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: AppSizes.fontMd,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(AppSizes.xs),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    onTap != null ? Icons.arrow_forward_ios : Icons.more_horiz,
                    color: Colors.white70,
                    size: AppSizes.iconSm,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              balance,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSizes.xs),
              Text(
                subtitle!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: AppSizes.fontSm,
                ),
              ),
            ],
            const SizedBox(height: AppSizes.md),
            // Decoración inferior
            Row(
              children: [
                _buildDecoCircle(0.3),
                const SizedBox(width: AppSizes.xs),
                _buildDecoCircle(0.2),
                const SizedBox(width: AppSizes.xs),
                _buildDecoCircle(0.1),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDecoCircle(double opacity) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
