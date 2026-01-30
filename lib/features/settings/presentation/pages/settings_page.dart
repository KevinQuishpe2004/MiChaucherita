import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/data/repositories/category_repository.dart';
import '../../../../core/domain/models/category.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../../auth/bloc/auth_state.dart';

// Funciones helper para diálogos
void _showCategoriesDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const _CategoriesDialog(),
  );
}

void _showCurrencyInfo(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Iconsax.money, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Moneda'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moneda actual: USD (\$)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'La aplicación utiliza el dólar estadounidense (USD) como moneda predeterminada para todas las transacciones y balances.',
          ),
          SizedBox(height: 8),
          Text(
            'El soporte para múltiples monedas estará disponible en futuras versiones.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

void _showAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('💰', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          const Text('MiChaucherita'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Versión 1.0.0'),
          SizedBox(height: 12),
          Text(
            'Una aplicación moderna de gestión de finanzas personales.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          SizedBox(height: 16),
          Text(
            'Desarrollado con Flutter + Supabase',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          SizedBox(height: 4),
          Text(
            '© 2025 - Proyecto Académico EPN',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

void _showHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Iconsax.message_question, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Ayuda y Soporte'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HelpItem(
            icon: Iconsax.wallet_add,
            title: 'Crear cuentas',
            description: 'Ve a Cuentas y presiona + para agregar una nueva cuenta bancaria, de efectivo o tarjeta.',
          ),
          const Divider(),
          _HelpItem(
            icon: Iconsax.receipt_add,
            title: 'Registrar transacciones',
            description: 'Usa el botón flotante (+) en el dashboard para agregar ingresos o gastos.',
          ),
          const Divider(),
          _HelpItem(
            icon: Iconsax.chart_2,
            title: 'Ver estadísticas',
            description: 'Accede a la sección de estadísticas para ver gráficos de tus finanzas.',
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesDialog extends StatefulWidget {
  const _CategoriesDialog();

  @override
  State<_CategoriesDialog> createState() => _CategoriesDialogState();
}

class _CategoriesDialogState extends State<_CategoriesDialog> {
  final CategoryRepository _categoryRepository = CategoryRepository();
  List<Category> _incomeCategories = [];
  List<Category> _expenseCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final income = await _categoryRepository.getByType('income');
      final expense = await _categoryRepository.getByType('expense');
      setState(() {
        _incomeCategories = income;
        _expenseCategories = expense;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null) return Colors.grey;
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Iconsax.category, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Categorías'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      tabs: const [
                        Tab(text: 'Ingresos'),
                        Tab(text: 'Gastos'),
                      ],
                      labelColor: AppColors.primary,
                      indicatorColor: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildCategoryList(_incomeCategories, AppColors.income),
                          _buildCategoryList(_expenseCategories, AppColors.expense),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildCategoryList(List<Category> categories, Color typeColor) {
    if (categories.isEmpty) {
      return const Center(child: Text('No hay categorías'));
    }
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getColorFromHex(category.color).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Iconsax.category,
              color: _getColorFromHex(category.color),
              size: 20,
            ),
          ),
          title: Text(category.name),
          dense: true,
        );
      },
    );
  }
}

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
                subtitle: 'Ver categorías disponibles',
                onTap: () {
                  _showCategoriesDialog(context);
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
                  _showCurrencyInfo(context);
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
                icon: Iconsax.sun_1,
                title: 'Tema',
                subtitle: 'Claro',
                trailing: const Icon(
                  Iconsax.sun_15,
                  color: AppColors.primary,
                ),
                onTap: () {},
              ),
              _SettingsTile(
                icon: Iconsax.colorfilter,
                title: 'Color de acento',
                subtitle: 'Naranja (predeterminado)',
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
                onTap: () => _showAboutDialog(context),
              ),
              _SettingsTile(
                icon: Iconsax.star,
                title: 'Calificar app',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Gracias por tu interés! Próximamente en tiendas'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Iconsax.message_question,
                title: 'Ayuda y soporte',
                onTap: () => _showHelpDialog(context),
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
