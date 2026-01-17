import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../../auth/bloc/auth_state.dart';

/// Página de configuración
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          // Perfil
          _ProfileCard().animate().fadeIn(duration: 300.ms),
          
          const SizedBox(height: AppSizes.lg),
          
          // Sección General
          _SettingsSection(
            title: 'General',
            children: [
              _SettingsTile(
                icon: Iconsax.category,
                title: 'Categorías',
                subtitle: 'Administrar categorías',
                onTap: () {
                  // TODO: Implementar página de categorías
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función en desarrollo')),
                  );
                },
              ),
              _SettingsTile(
                icon: Iconsax.wallet_3,
                title: 'Cuentas',
                subtitle: 'Administrar cuentas',
                onTap: () => context.push('/accounts'),
              ),
              _SettingsTile(
                icon: Iconsax.money,
                title: 'Moneda',
                subtitle: 'USD (\$)',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función en desarrollo')),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          // Sección Apariencia
          _SettingsSection(
            title: 'Apariencia',
            children: [
              _SettingsTile(
                icon: Iconsax.moon,
                title: 'Tema oscuro',
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                  activeTrackColor: AppColors.primary,
                  activeColor: AppColors.primary,
                ),
                onTap: () {},
              ),
              _SettingsTile(
                icon: Iconsax.colorfilter,
                title: 'Color de acento',
                subtitle: 'Naranja',
                onTap: () {},
              ),
            ],
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          // Sección Seguridad
          _SettingsSection(
            title: 'Seguridad',
            children: [
              _SettingsTile(
                icon: Iconsax.lock,
                title: 'Bloqueo de app',
                subtitle: 'PIN, huella o Face ID',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Iconsax.shield_tick,
                title: 'Copia de seguridad',
                subtitle: 'Exportar datos',
                onTap: () {},
              ),
            ],
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          // Sección Acerca de
          _SettingsSection(
            title: 'Acerca de',
            children: [
              _SettingsTile(
                icon: Iconsax.info_circle,
                title: 'Versión',
                subtitle: '1.0.0',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Iconsax.star,
                title: 'Calificar app',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Iconsax.message_question,
                title: 'Ayuda y soporte',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: AppSizes.lg),

          // Cerrar sesión
          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthUnauthenticated) {
                context.go('/login');
              }
            },
            builder: (context, state) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: _SettingsTile(
                  icon: Iconsax.logout,
                  title: 'Cerrar sesión',
                  trailing: const Icon(
                    Iconsax.arrow_right_3,
                    size: AppSizes.iconSm,
                    color: Colors.red,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Cerrar sesión'),
                        content: const Text(
                          '¿Estás seguro que deseas cerrar sesión?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              context.read<AuthBloc>().add(
                                    const AuthLogoutRequested(),
                                  );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Cerrar sesión'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
            },
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String userName = 'Usuario';
        String userEmail = 'correo@ejemplo.com';

        if (state is AuthAuthenticated) {
          userName = state.user.name;
          userEmail = state.user.email;
        }

        return Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppSizes.fontXl,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: AppSizes.fontSm,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(
                  Iconsax.edit,
                  color: Colors.white,
                  size: AppSizes.iconSm,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSizes.sm,
            bottom: AppSizes.sm,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final isLast = entry.key == children.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast)
                    const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.md,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(
                  icon,
                  size: AppSizes.iconSm,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppSizes.fontMd,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: AppSizes.fontSm,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Iconsax.arrow_right_3,
                    size: AppSizes.iconSm,
                    color: AppColors.textHint,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
