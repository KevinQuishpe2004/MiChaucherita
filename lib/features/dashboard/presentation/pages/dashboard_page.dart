import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/data/repositories/category_repository.dart';
import '../../../../core/domain/models/category.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../accounts/bloc/account_bloc.dart';
import '../../../accounts/bloc/account_state.dart';
import '../../../transactions/bloc/transaction_bloc.dart';
import '../../../transactions/bloc/transaction_state.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/quick_actions.dart';
import '../widgets/month_selector.dart';

/// Página principal del Dashboard
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime _selectedMonth = DateTime.now();
  final CategoryRepository _categoryRepository = CategoryRepository();
  Map<String, Category> _categoriesCache = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryRepository.getAll();
      setState(() {
        _categoriesCache = {for (var cat in categories) cat.id: cat};
      });
    } catch (e) {
      // Silently fail, categories will show as 'General'
    }
  }

  Category? _getCategoryById(String categoryId) {
    return _categoriesCache[categoryId];
  }

  IconData _getCategoryIcon(String? iconName) {
    if (iconName == null) return Iconsax.category;
    
    final iconMap = {
      'restaurant': Iconsax.coffee,
      'directions_car': Iconsax.car,
      'home': Iconsax.home_2,
      'receipt_long': Iconsax.receipt_1,
      'local_hospital': Iconsax.health,
      'movie': Iconsax.game,
      'school': Iconsax.book_1,
      'shopping_bag': Iconsax.bag_2,
      'checkroom': Iconsax.tag,
      'more_horiz': Iconsax.more_circle,
      'payments': Iconsax.wallet_money,
      'work': Iconsax.code,
      'trending_up': Iconsax.chart_2,
      'store': Iconsax.shop,
      'attach_money': Iconsax.dollar_circle,
    };
    
    return iconMap[iconName] ?? Iconsax.category;
  }

  Color _getCategoryColor(String? hexColor) {
    if (hexColor == null) return AppColors.primary;
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: DashboardHeader(
                userName: 'Usuario',
                onNotificationTap: () {},
              ),
            ),
            
            // Balance Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: BlocBuilder<AccountBloc, AccountState>(
                  builder: (context, state) {
                    final balance = state is AccountLoaded 
                        ? '\$${state.totalBalance.toStringAsFixed(2)}'
                        : '\$0.00';
                    
                    return BalanceCard(
                      title: AppStrings.totalBalance,
                      balance: balance,
                      subtitle: 'Actualizado ahora',
                      icon: Iconsax.wallet_3,
                    );
                  },
                ),
              ),
            ),
            
            // Selector de mes
            SliverToBoxAdapter(
              child: MonthSelector(
                selectedMonth: _selectedMonth,
                onMonthChanged: (month) {
                  setState(() => _selectedMonth = month);
                },
              ),
            ),
            
            // Summary Cards (Ingresos y Gastos)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: BlocBuilder<TransactionBloc, TransactionState>(
                  builder: (context, state) {
                    final income = state is TransactionLoaded 
                        ? '\$${state.totalIncome.toStringAsFixed(2)}'
                        : '\$0.00';
                    final expense = state is TransactionLoaded 
                        ? '\$${state.totalExpense.toStringAsFixed(2)}'
                        : '\$0.00';
                    
                    return Row(
                      children: [
                        Expanded(
                          child: SummaryCard.income(
                            amount: income,
                            animationDelay: 100,
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: SummaryCard.expense(
                            amount: expense,
                            animationDelay: 200,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSizes.lg),
            ),
            
            // Acciones rápidas
            const SliverToBoxAdapter(
              child: QuickActions(),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSizes.lg),
            ),
            
            // Sección de Cuentas
            SliverToBoxAdapter(
              child: SectionHeader(
                title: AppStrings.myAccounts,
                actionText: AppStrings.viewAll,
                onAction: () => context.go('/accounts'),
              ),
            ),
            
            // Lista horizontal de cuentas
            SliverToBoxAdapter(
              child: BlocBuilder<AccountBloc, AccountState>(
                builder: (context, state) {
                  if (state is AccountLoading) {
                    return const SizedBox(
                      height: 140,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (state is AccountLoaded) {
                    final accounts = state.accounts;
                    
                    if (accounts.isEmpty) {
                      return const SizedBox(
                        height: 140,
                        child: Center(
                          child: Text('No hay cuentas'),
                        ),
                      );
                    }
                    
                    return SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                        itemCount: accounts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          return AccountCard(
                            name: account.name,
                            balance: '\$${account.balance.toStringAsFixed(2)}',
                            icon: _getAccountIcon(account.type),
                            color: _getAccountColor(account.type),
                            animationDelay: index * 100,
                            onTap: () {},
                          );
                        },
                      ),
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSizes.lg),
            ),
            
            // Sección de movimientos recientes
            SliverToBoxAdapter(
              child: SectionHeader(
                title: AppStrings.recentTransactions,
                actionText: AppStrings.viewAll,
                onAction: () => context.go('/transactions'),
              ),
            ),
            
            // Lista de transacciones recientes
            SliverToBoxAdapter(
              child: BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  if (state is TransactionLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (state is TransactionLoaded) {
                    final transactions = state.transactions.take(4).toList();
                    
                    if (transactions.isEmpty) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                        padding: const EdgeInsets.all(AppSizes.xl),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text('No hay transacciones'),
                        ),
                      );
                    }
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < transactions.length; i++) ...[
                            if (i > 0) const Divider(height: 1, indent: 72),
                            Builder(
                              builder: (context) {
                                final transaction = transactions[i];
                                final category = _getCategoryById(transaction.categoryId);
                                return TransactionTile(
                                  title: transaction.description ?? 'Sin título',
                                  category: category?.name ?? 'General',
                                  amount: '\$${transaction.amount.toStringAsFixed(2)}',
                                  date: _formatDate(transaction.date),
                                  type: _mapTransactionType(transaction.type),
                                  categoryIcon: _getCategoryIcon(category?.icon),
                                  categoryColor: _getCategoryColor(category?.color),
                                  animationDelay: i * 50,
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
            ),
            
            // Sección de Categorías del mes - Comentado temporalmente
            // const SliverToBoxAdapter(
            //   child: SizedBox(height: AppSizes.lg),
            // ),
            
            // Espacio para el bottom nav
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) return 'Hoy';
    if (dateOnly == yesterday) return 'Ayer';
    return '${date.day}/${date.month}';
  }
  
  TransactionType _mapTransactionType(String type) {
    if (type == 'income') return TransactionType.income;
    if (type == 'expense') return TransactionType.expense;
    return TransactionType.transfer;
  }

  IconData _getAccountIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
      case 'efectivo':
        return Iconsax.wallet;
      case 'bank':
      case 'banco':
        return Iconsax.bank;
      case 'card':
      case 'tarjeta':
        return Iconsax.card;
      case 'savings':
      case 'ahorros':
        return Iconsax.save_2;
      default:
        return Iconsax.wallet;
    }
  }

  Color _getAccountColor(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
      case 'efectivo':
        return AppColors.primary;
      case 'bank':
      case 'banco':
        return Colors.blue;
      case 'card':
      case 'tarjeta':
        return Colors.purple;
      case 'savings':
      case 'ahorros':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }
}

/// Tarjeta para agregar nueva cuenta
class _AddAccountCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddAccountCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.add,
                color: AppColors.primary,
                size: AppSizes.iconLg,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            const Text(
              'Nueva Cuenta',
              style: TextStyle(
                fontSize: AppSizes.fontMd,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 300.ms).fadeIn().scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
        );
  }
}
