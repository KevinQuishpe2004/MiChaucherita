import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

/// Header del Dashboard con saludo y notificaciones
class DashboardHeader extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const DashboardHeader({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.onNotificationTap,
    this.onProfileTap,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return '¡Buenos días!';
    if (hour < 18) return '¡Buenas tardes!';
    return '¡Buenas noches!';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        avatarUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Iconsax.user,
                      color: Colors.white,
                      size: AppSizes.iconMd,
                    ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          // Texto de saludo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: AppSizes.fontXl,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Botón de notificaciones
          _HeaderButton(
            icon: Iconsax.notification,
            onTap: onNotificationTap,
            hasNotification: true,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool hasNotification;

  const _HeaderButton({
    required this.icon,
    this.onTap,
    this.hasNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(
                icon,
                color: AppColors.textSecondary,
                size: AppSizes.iconMd,
              ),
            ),
          ),
        ),
        if (hasNotification)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.expense,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
