import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/data/repositories/category_repository.dart';
import '../../../../core/domain/models/category.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../transactions/bloc/transaction_bloc.dart';
import '../../../transactions/bloc/transaction_state.dart';
import '../../../accounts/bloc/account_bloc.dart';
import '../../../accounts/bloc/account_state.dart';

/// Página de estadísticas mejorada
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _touchedIndex = -1;
  int _selectedPeriod = 0; // 0: 7 días, 1: 30 días, 2: Este mes
  final CategoryRepository _categoryRepository = CategoryRepository();
  Map<String, Category> _categoriesCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryRepository.getAll();
      setState(() {
        _categoriesCache = {for (var cat in categories) cat.id: cat};
      });
    } catch (e) {
      // Silently fail
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Obtener transacciones filtradas por período
  List<dynamic> _getFilteredTransactions(List<dynamic> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    DateTime startDate;
    switch (_selectedPeriod) {
      case 0: // Últimos 7 días
        startDate = today.subtract(const Duration(days: 6));
        break;
      case 1: // Últimos 30 días
        startDate = today.subtract(const Duration(days: 29));
        break;
      case 2: // Este mes
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = today.subtract(const Duration(days: 6));
    }
    
    return transactions.where((t) {
      final transactionDate = DateTime(t.date.year, t.date.month, t.date.day);
      return transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             transactionDate.isBefore(today.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Iconsax.calendar_1),
            onSelected: (value) => setState(() => _selectedPeriod = value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 0,
                child: Row(
                  children: [
                    Icon(
                      _selectedPeriod == 0 ? Icons.check_circle : Icons.circle_outlined,
                      color: _selectedPeriod == 0 ? AppColors.primary : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Últimos 7 días'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(
                      _selectedPeriod == 1 ? Icons.check_circle : Icons.circle_outlined,
                      color: _selectedPeriod == 1 ? AppColors.primary : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Últimos 30 días'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(
                      _selectedPeriod == 2 ? Icons.check_circle : Icons.circle_outlined,
                      color: _selectedPeriod == 2 ? AppColors.primary : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Este mes'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTransactions = state is TransactionLoaded ? state.transactions : [];
          final transactions = _getFilteredTransactions(allTransactions);
          
          // Determinar el tipo según la pestaña seleccionada
          final selectedType = _tabController.index == 0 ? 'expense' : 'income';
          
          // Calcular totales del período
          final expenses = transactions.where((t) => t.type == 'expense').toList();
          final incomes = transactions.where((t) => t.type == 'income').toList();
          final transfers = transactions.where((t) => t.type == 'transfer').toList();
          
          final totalExpenses = expenses.fold<double>(0, (sum, t) => sum + t.amount);
          final totalIncomes = incomes.fold<double>(0, (sum, t) => sum + t.amount);
          final totalTransfers = transfers.fold<double>(0, (sum, t) => sum + t.amount);
          final balance = totalIncomes - totalExpenses;
          
          // Usar las transacciones del tipo seleccionado
          final selectedTransactions = selectedType == 'expense' ? expenses : incomes;
          
          // Agrupar por categoría
          final Map<String, double> amountByCategory = {};
          final Map<String, int> countByCategory = {};
          for (var transaction in selectedTransactions) {
            amountByCategory[transaction.categoryId] = 
                (amountByCategory[transaction.categoryId] ?? 0) + transaction.amount;
            countByCategory[transaction.categoryId] = 
                (countByCategory[transaction.categoryId] ?? 0) + 1;
          }
          
          // Ordenar categorías por monto
          final sortedCategories = amountByCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          final totalSelected = selectedTransactions.fold<double>(0, (sum, t) => sum + t.amount);

          // Calcular promedio diario
          final days = _selectedPeriod == 0 ? 7 : (_selectedPeriod == 1 ? 30 : DateTime.now().day);
          final avgExpensePerDay = days > 0 ? totalExpenses / days : 0.0;
          final avgIncomePerDay = days > 0 ? totalIncomes / days : 0.0;

          return ListView(
            padding: const EdgeInsets.all(AppSizes.md),
            children: [
              // Indicador de período seleccionado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.calendar_1, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      _getPeriodLabel(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
              
              const SizedBox(height: AppSizes.lg),
              
              // Balance general
              _BalanceCard(
                income: totalIncomes,
                expense: totalExpenses,
                balance: balance,
                transfers: totalTransfers,
              ),
              
              const SizedBox(height: AppSizes.lg),

              // Tabs de Ingresos/Egresos
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: [
                    Tab(text: 'Gastos (${expenses.length})'),
                    Tab(text: 'Ingresos (${incomes.length})'),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
              
              const SizedBox(height: AppSizes.lg),
              
              // Resumen con promedios
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: selectedType == 'expense' ? 'Total Gastos' : 'Total Ingresos',
                      amount: '\$${totalSelected.toStringAsFixed(2)}',
                      icon: selectedType == 'expense' ? Iconsax.arrow_up_1 : Iconsax.arrow_down,
                      color: selectedType == 'expense' ? AppColors.expense : AppColors.income,
                      subtitle: '${selectedTransactions.length} transacciones',
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: _StatCard(
                      title: 'Promedio diario',
                      amount: '\$${(selectedType == 'expense' ? avgExpensePerDay : avgIncomePerDay).toStringAsFixed(2)}',
                      icon: Iconsax.chart_1,
                      color: AppColors.primary,
                      subtitle: 'por día',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSizes.lg),
              
              // Gráfico de tendencia (líneas)
              _TrendChart(
                transactions: transactions,
                selectedPeriod: _selectedPeriod,
              ),
              
              const SizedBox(height: AppSizes.lg),
              
              // Gráfico de pie mejorado - Responsive
              Container(
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            selectedType == 'expense' ? 'Distribución de Gastos' : 'Distribución de Ingresos',
                            style: const TextStyle(
                              fontSize: AppSizes.fontLg,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Text(
                            '${sortedCategories.length} categorías',
                            style: const TextStyle(
                              fontSize: AppSizes.fontXs,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.lg),
                    if (sortedCategories.isEmpty)
                      const SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.chart, size: 48, color: AppColors.textHint),
                              SizedBox(height: 8),
                              Text('No hay datos para mostrar', 
                                style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          
                          // Móvil pequeño: columna vertical
                          if (width < 350) {
                            return Column(
                              children: [
                                SizedBox(
                                  height: 180,
                                  child: _buildPieChart(sortedCategories, totalSelected),
                                ),
                                const SizedBox(height: AppSizes.md),
                                _buildLegendHorizontal(sortedCategories, totalSelected, countByCategory),
                              ],
                            );
                          }
                          
                          // Tablet/Desktop grande: gráfico más grande centrado
                          if (width > 600) {
                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 220,
                                      height: 220,
                                      child: _buildPieChart(sortedCategories, totalSelected, centerRadius: 50),
                                    ),
                                    const SizedBox(width: AppSizes.xl),
                                    SizedBox(
                                      width: 250,
                                      child: _buildLegendVertical(sortedCategories, totalSelected, countByCategory),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }
                          
                          // Móvil/Tablet pequeña: fila compacta
                          return Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 180,
                                  child: _buildPieChart(sortedCategories, totalSelected),
                                ),
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                flex: 3,
                                child: _buildLegendVertical(sortedCategories, totalSelected, countByCategory),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),
              
              const SizedBox(height: AppSizes.lg),
              
              // Gráfico de barras con fechas reales
              _WeeklyBarChart(
                transactions: selectedTransactions,
                selectedPeriod: _selectedPeriod,
                isExpense: selectedType == 'expense',
              ),
              
              const SizedBox(height: AppSizes.lg),
              
              // Top categorías con más detalle
              SectionHeader(
                title: 'Top Categorías ${selectedType == 'expense' ? 'de Gasto' : 'de Ingreso'}',
                padding: const EdgeInsets.only(bottom: AppSizes.md),
              ),
              
              if (sortedCategories.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          selectedType == 'expense' ? Iconsax.money_send : Iconsax.money_recive,
                          size: 48,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay ${selectedType == 'expense' ? 'gastos' : 'ingresos'} en este período',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...sortedCategories.take(5).map((entry) {
                  final category = _categoriesCache[entry.key];
                  final percentage = totalSelected > 0 
                      ? (entry.value / totalSelected * 100) 
                      : 0.0;
                  final count = countByCategory[entry.key] ?? 0;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: _CategoryDetailCard(
                      name: category?.name ?? 'Desconocida',
                      amount: entry.value,
                      icon: _getCategoryIcon(category?.icon),
                      color: _getCategoryColor(category?.color),
                      isExpense: selectedType == 'expense',
                      percentage: percentage,
                      transactionCount: count,
                      animationDelay: sortedCategories.indexOf(entry) * 100,
                    ),
                  );
                }),
              
              const SizedBox(height: AppSizes.lg),
              
              // Resumen de cuentas
              BlocBuilder<AccountBloc, AccountState>(
                builder: (context, accountState) {
                  if (accountState is AccountLoaded && accountState.accounts.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: 'Resumen por Cuenta',
                          padding: EdgeInsets.only(bottom: AppSizes.md),
                        ),
                        ...accountState.accounts.take(3).map((account) {
                          // Calcular movimientos por cuenta
                          final accountTransactions = transactions.where(
                            (t) => t.accountId == account.id
                          ).toList();
                          final accountIncome = accountTransactions
                              .where((t) => t.type == 'income')
                              .fold<double>(0, (sum, t) => sum + t.amount);
                          final accountExpense = accountTransactions
                              .where((t) => t.type == 'expense')
                              .fold<double>(0, (sum, t) => sum + t.amount);
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSizes.sm),
                            child: _AccountSummaryCard(
                              accountName: account.name,
                              balance: account.balance,
                              income: accountIncome,
                              expense: accountExpense,
                              transactionCount: accountTransactions.length,
                            ),
                          );
                        }),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              const SizedBox(height: 120),
            ],
          );
        },
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 0:
        return 'Últimos 7 días';
      case 1:
        return 'Últimos 30 días';
      case 2:
        final now = DateTime.now();
        return DateFormat('MMMM yyyy', 'es').format(now);
      default:
        return 'Últimos 7 días';
    }
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

  Widget _buildPieChart(List<MapEntry<String, double>> categories, double total, {double centerRadius = 40}) {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        sectionsSpace: 2,
        centerSpaceRadius: centerRadius,
        sections: _generatePieSections(categories, total),
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections(List<MapEntry<String, double>> categories, double total) {
    if (categories.isEmpty || total == 0) {
      return [];
    }
    
    final topCategories = categories.take(5).toList();
    
    // Si hay más categorías, agrupar el resto en "Otros"
    if (categories.length > 5) {
      final othersTotal = categories.skip(5).fold<double>(0, (sum, e) => sum + e.value);
      if (othersTotal > 0) {
        topCategories.add(MapEntry('others', othersTotal));
      }
    }
    
    return topCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final categoryEntry = entry.value;
      final category = _categoriesCache[categoryEntry.key];
      final percentage = (categoryEntry.value / total * 100);
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 55.0 : 45.0;
      
      Color color;
      if (categoryEntry.key == 'others') {
        color = AppColors.textHint;
      } else {
        color = _getCategoryColor(category?.color);
      }
      
      return PieChartSectionData(
        value: percentage,
        color: color,
        radius: radius,
        title: isTouched ? '${percentage.toInt()}%' : '',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegendVertical(
    List<MapEntry<String, double>> categories, 
    double total,
    Map<String, int> countByCategory,
  ) {
    if (categories.isEmpty || total == 0) {
      return const Text('No hay datos', style: TextStyle(color: AppColors.textSecondary));
    }
    
    final topCategories = categories.take(5).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: topCategories.map((entry) {
          final category = _categoriesCache[entry.key];
          final percentage = (entry.value / total * 100).toInt();
          final count = countByCategory[entry.key] ?? 0;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category?.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category?.name ?? 'Desconocida',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$percentage% • $count trans.',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Leyenda horizontal para pantallas pequeñas
  Widget _buildLegendHorizontal(
    List<MapEntry<String, double>> categories, 
    double total,
    Map<String, int> countByCategory,
  ) {
    if (categories.isEmpty || total == 0) {
      return const Text('No hay datos', style: TextStyle(color: AppColors.textSecondary));
    }
    
    final topCategories = categories.take(5).toList();

    return Wrap(
      spacing: AppSizes.md,
      runSpacing: AppSizes.sm,
      alignment: WrapAlignment.center,
      children: topCategories.map((entry) {
        final category = _categoriesCache[entry.key];
        final percentage = (entry.value / total * 100).toInt();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getCategoryColor(category?.color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category?.color),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${category?.name ?? 'Desconocida'} $percentage%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Widget de balance general
class _BalanceCard extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;
  final double transfers;

  const _BalanceCard({
    required this.income,
    required this.expense,
    required this.balance,
    required this.transfers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Balance del período',
            style: TextStyle(
              color: Colors.white70,
              fontSize: AppSizes.fontSm,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: _BalanceItem(
                  label: 'Ingresos',
                  amount: income,
                  icon: Iconsax.arrow_down,
                  isPositive: true,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
              ),
              Expanded(
                child: _BalanceItem(
                  label: 'Gastos',
                  amount: expense,
                  icon: Iconsax.arrow_up_1,
                  isPositive: false,
                ),
              ),
              if (transfers > 0) ...[
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white24,
                ),
                Expanded(
                  child: _BalanceItem(
                    label: 'Transferencias',
                    amount: transfers,
                    icon: Icons.swap_horiz,
                    isPositive: true,
                    isTransfer: true,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final bool isPositive;
  final bool isTransfer;

  const _BalanceItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.isPositive,
    this.isTransfer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Widget de tarjeta de estadísticas
class _StatCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(icon, size: AppSizes.iconSm, color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            title,
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontSize: AppSizes.fontXl,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: AppSizes.fontXs,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

// Gráfico de tendencia mejorado
class _TrendChart extends StatelessWidget {
  final List<dynamic> transactions;
  final int selectedPeriod;

  const _TrendChart({
    required this.transactions,
    required this.selectedPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = selectedPeriod == 0 ? 7 : (selectedPeriod == 1 ? 30 : now.day);
    
    // Calcular datos diarios
    final incomeByDay = <DateTime, double>{};
    final expenseByDay = <DateTime, double>{};
    
    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1 - i));
      incomeByDay[date] = 0;
      expenseByDay[date] = 0;
    }
    
    for (var t in transactions) {
      final date = DateTime(t.date.year, t.date.month, t.date.day);
      if (t.type == 'income') {
        incomeByDay[date] = (incomeByDay[date] ?? 0) + t.amount;
      } else if (t.type == 'expense') {
        expenseByDay[date] = (expenseByDay[date] ?? 0) + t.amount;
      }
    }
    
    final sortedDates = incomeByDay.keys.toList()..sort();
    
    // Encontrar el máximo para escalar
    double maxY = 0;
    for (var date in sortedDates) {
      final income = incomeByDay[date] ?? 0;
      final expense = expenseByDay[date] ?? 0;
      if (income > maxY) maxY = income;
      if (expense > maxY) maxY = expense;
    }
    maxY = maxY > 0 ? maxY * 1.2 : 100;
    
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tendencia',
                style: TextStyle(
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  _LegendDot(color: AppColors.income, label: 'Ingresos'),
                  const SizedBox(width: 12),
                  _LegendDot(color: AppColors.expense, label: 'Gastos'),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: days > 7 ? (days / 5).ceil().toDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedDates.length) {
                          return const SizedBox.shrink();
                        }
                        final date = sortedDates[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('d/M').format(date),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  // Línea de ingresos
                  LineChartBarData(
                    spots: sortedDates.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), incomeByDay[e.value] ?? 0);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.income,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: days <= 7,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.income,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.income.withOpacity(0.1),
                    ),
                  ),
                  // Línea de gastos
                  LineChartBarData(
                    spots: sortedDates.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), expenseByDay[e.value] ?? 0);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.expense,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: days <= 7,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.expense,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.expense.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isIncome = spot.barIndex == 0;
                        return LineTooltipItem(
                          '\$${spot.y.toStringAsFixed(2)}',
                          TextStyle(
                            color: isIncome ? AppColors.income : AppColors.expense,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// Gráfico de barras semanal con fechas reales
class _WeeklyBarChart extends StatelessWidget {
  final List<dynamic> transactions;
  final int selectedPeriod;
  final bool isExpense;

  const _WeeklyBarChart({
    required this.transactions,
    required this.selectedPeriod,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = selectedPeriod == 0 ? 7 : (selectedPeriod == 1 ? 14 : now.day.clamp(1, 14));
    
    // Calcular datos diarios
    final dailyData = <DateTime, double>{};
    
    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1 - i));
      dailyData[date] = 0;
    }
    
    for (var t in transactions) {
      final date = DateTime(t.date.year, t.date.month, t.date.day);
      if (dailyData.containsKey(date)) {
        dailyData[date] = (dailyData[date] ?? 0) + t.amount;
      }
    }
    
    final sortedDates = dailyData.keys.toList()..sort();
    
    // Encontrar el máximo
    double maxY = dailyData.values.fold(0.0, (max, val) => val > max ? val : max);
    maxY = maxY > 0 ? maxY * 1.2 : 100;
    
    final color = isExpense ? AppColors.expense : AppColors.income;
    
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isExpense ? 'Gastos por día' : 'Ingresos por día',
                style: const TextStyle(
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Text(
                  'Últimos $days días',
                  style: TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final date = sortedDates[group.x];
                      return BarTooltipItem(
                        '${DateFormat('d MMM', 'es').format(date)}\n\$${rod.toY.toStringAsFixed(2)}',
                        TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedDates.length) {
                          return const SizedBox.shrink();
                        }
                        final date = sortedDates[index];
                        final isToday = date.day == now.day && 
                                       date.month == now.month && 
                                       date.year == now.year;
                        
                        // Mostrar menos etiquetas si hay muchos días
                        if (days > 7 && index % 2 != 0 && !isToday) {
                          return const SizedBox.shrink();
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getDayName(date),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isToday ? AppColors.primary : AppColors.textSecondary,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isToday ? AppColors.primary : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                barGroups: sortedDates.asMap().entries.map((entry) {
                  final amount = dailyData[entry.value] ?? 0;
                  final isToday = entry.value.day == now.day && 
                                 entry.value.month == now.month && 
                                 entry.value.year == now.year;
                  
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: amount,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isToday
                              ? [AppColors.primary.withOpacity(0.6), AppColors.primary]
                              : [color.withOpacity(0.6), color],
                        ),
                        width: days > 10 ? 12 : 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }
  
  String _getDayName(DateTime date) {
    const days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    return days[date.weekday % 7];
  }
}

// Tarjeta de categoría con más detalle
class _CategoryDetailCard extends StatelessWidget {
  final String name;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isExpense;
  final double percentage;
  final int transactionCount;
  final int animationDelay;

  const _CategoryDetailCard({
    required this.name,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isExpense,
    required this.percentage,
    required this.transactionCount,
    required this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: AppSizes.fontMd,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$transactionCount transacciones',
                      style: const TextStyle(
                        fontSize: AppSizes.fontXs,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isExpense ? '-' : '+'}\$${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: AppSizes.fontLg,
                      fontWeight: FontWeight.bold,
                      color: isExpense ? AppColors.expense : AppColors.income,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: AppSizes.fontXs,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: animationDelay)).fadeIn().slideX(begin: 0.05, end: 0);
  }
}

// Tarjeta de resumen por cuenta
class _AccountSummaryCard extends StatelessWidget {
  final String accountName;
  final double balance;
  final double income;
  final double expense;
  final int transactionCount;

  const _AccountSummaryCard({
    required this.accountName,
    required this.balance,
    required this.income,
    required this.expense,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Iconsax.wallet_3, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accountName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: AppSizes.fontMd,
                        ),
                      ),
                      Text(
                        '$transactionCount movimientos',
                        style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '\$${balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          const Divider(),
          const SizedBox(height: AppSizes.xs),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Iconsax.arrow_down, size: 14, color: AppColors.income),
                    const SizedBox(width: 4),
                    Text(
                      '+\$${income.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: AppSizes.fontSm,
                        color: AppColors.income,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Iconsax.arrow_up_1, size: 14, color: AppColors.expense),
                    const SizedBox(width: 4),
                    Text(
                      '-\$${expense.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: AppSizes.fontSm,
                        color: AppColors.expense,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }
}
