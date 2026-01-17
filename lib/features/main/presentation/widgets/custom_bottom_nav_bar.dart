import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

/// Item de la barra de navegación
class NavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Barra de navegación inferior personalizada con FAB central
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabPressed;
  final List<NavBarItem> items;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabPressed,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Barra de navegación con curva
          CustomPaint(
            size: Size(screenWidth, AppSizes.bottomNavHeight),
            painter: _NavBarPainter(
              color: AppColors.surface,
            ),
            child: SizedBox(
              height: AppSizes.bottomNavHeight,
              width: screenWidth,
              child: Row(
                children: [
                  // Items de la izquierda (2 items)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavBarItemWidget(
                          item: items[0],
                          isSelected: currentIndex == 0,
                          onTap: () => onTap(0),
                        ),
                        _NavBarItemWidget(
                          item: items[1],
                          isSelected: currentIndex == 1,
                          onTap: () => onTap(1),
                        ),
                      ],
                    ),
                  ),
                  // Espacio para el FAB central
                  const SizedBox(width: 90),
                  // Items de la derecha (2 items)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavBarItemWidget(
                          item: items[3],
                          isSelected: currentIndex == 3,
                          onTap: () => onTap(3),
                        ),
                        _NavBarItemWidget(
                          item: items[4],
                          isSelected: currentIndex == 4,
                          onTap: () => onTap(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // FAB Central
          Positioned(
            top: -28,
            child: _CentralFAB(
              onPressed: onFabPressed,
              isSelected: currentIndex == 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de item individual de la barra de navegación
class _NavBarItemWidget extends StatelessWidget {
  final NavBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        height: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? AppColors.primary : AppColors.textHint,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// FAB central con animación
class _CentralFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isSelected;

  const _CentralFAB({
    required this.onPressed,
    required this.isSelected,
  });

  @override
  State<_CentralFAB> createState() => _CentralFABState();
}

class _CentralFABState extends State<_CentralFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}

/// Painter personalizado para la curva de la barra de navegación
class _NavBarPainter extends CustomPainter {
  final Color color;

  _NavBarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Punto inicial
    path.moveTo(0, 20);
    
    // Curva superior izquierda
    path.quadraticBezierTo(0, 0, 20, 0);
    
    // Línea hasta el inicio de la curva del FAB
    path.lineTo(size.width / 2 - 50, 0);
    
    // Curva para el FAB (más pronunciada y suave)
    path.quadraticBezierTo(
      size.width / 2 - 30, 0,
      size.width / 2 - 25, 10,
    );
    path.quadraticBezierTo(
      size.width / 2 - 15, 35,
      size.width / 2, 38,
    );
    path.quadraticBezierTo(
      size.width / 2 + 15, 35,
      size.width / 2 + 25, 10,
    );
    path.quadraticBezierTo(
      size.width / 2 + 30, 0,
      size.width / 2 + 50, 0,
    );
    
    // Línea hasta el final
    path.lineTo(size.width - 20, 0);
    
    // Curva superior derecha
    path.quadraticBezierTo(size.width, 0, size.width, 20);
    
    // Línea hasta abajo
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
