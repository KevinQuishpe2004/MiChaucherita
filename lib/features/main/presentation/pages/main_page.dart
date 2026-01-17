import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../widgets/custom_bottom_nav_bar.dart';

/// Página principal con navegación inferior
class MainPage extends StatefulWidget {
  final Widget child;

  const MainPage({
    super.key,
    required this.child,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<String> _routes = [
    '/dashboard',
    '/accounts',
    '/transactions',
    '/statistics',
    '/settings',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentIndex();
  }

  void _updateCurrentIndex() {
    final location = GoRouterState.of(context).uri.path;
    final index = _routes.indexWhere((route) => location.startsWith(route));
    if (index != -1 && index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  void _onItemTapped(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
      
      // Feedback háptico sutil
      HapticFeedback.lightImpact();
      
      context.go(_routes[index]);
    }
  }

  void _onFabPressed() {
    HapticFeedback.mediumImpact();
    _showQuickActionSheet();
  }

  void _showQuickActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        onFabPressed: _onFabPressed,
        items: const [
          NavBarItem(icon: Iconsax.home_2, activeIcon: Iconsax.home_25, label: 'Inicio'),
          NavBarItem(icon: Iconsax.wallet_3, activeIcon: Iconsax.wallet_35, label: 'Cuentas'),
          NavBarItem(icon: Iconsax.add, activeIcon: Iconsax.add, label: ''), // Placeholder para FAB
          NavBarItem(icon: Iconsax.chart_2, activeIcon: Iconsax.chart_25, label: 'Estadísticas'),
          NavBarItem(icon: Iconsax.setting_2, activeIcon: Iconsax.setting_25, label: 'Ajustes'),
        ],
      ),
    );
  }
}

/// Hoja de acciones rápidas para crear transacciones
class QuickActionSheet extends StatelessWidget {
  const QuickActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            // Título
            const Text(
              'Nuevo Movimiento',
              style: TextStyle(
                fontSize: AppSizes.fontXl,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            const Text(
              '¿Qué tipo de movimiento deseas registrar?',
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            // Opciones
            Row(
              children: [
                Expanded(
                  child: _ActionOption(
                    icon: Iconsax.arrow_down,
                    label: 'Ingreso',
                    color: AppColors.income,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/add-transaction?type=income');
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _ActionOption(
                    icon: Iconsax.arrow_up_1,
                    label: 'Egreso',
                    color: AppColors.expense,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/add-transaction?type=expense');
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _ActionOption(
                    icon: Iconsax.arrow_swap_horizontal,
                    label: 'Transferencia',
                    color: AppColors.transfer,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/add-transaction?type=transfer');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }
}

class _ActionOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionOption({
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
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.lg,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: AppSizes.iconLg,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
