import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/data/repositories/category_repository.dart';
import '../../../../core/domain/models/category.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../transactions/bloc/transaction_bloc.dart';
import '../../../transactions/bloc/transaction_state.dart';

/// Página de estadísticas
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _touchedIndex = -1;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Iconsax.calendar_1),
          ),
        ],
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = state is TransactionLoaded ? state.transactions : [];
          
          // Determinar el tipo según la pestaña seleccionada
          final selectedType = _tabController.index == 0 ? 'expense' : 'income';
          
          // Calcular totales
          final expenses = transactions.where((t) => t.type == 'expense').toList();
          final incomes = transactions.where((t) => t.type == 'income').toList();
          
          final totalExpenses = expenses.fold<double>(0, (sum, t) => sum + t.amount);
          final totalIncomes = incomes.fold<double>(0, (sum, t) => sum + t.amount);
          
          // Usar las transacciones del tipo seleccionado
          final selectedTransactions = selectedType == 'expense' ? expenses : incomes;
          
          // Agrupar por categoría
          final Map<String, double> amountByCategory = {};
          for (var transaction in selectedTransactions) {
            amountByCategory[transaction.categoryId] = 
                (amountByCategory[transaction.categoryId] ?? 0) + transaction.amount;
          }
          
          // Ordenar categorías por monto
          final sortedCategories = amountByCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          final totalSelected = selectedTransactions.fold<double>(0, (sum, t) => sum + t.amount);

          return ListView(
            padding: const EdgeInsets.all(AppSizes.md),
            children: [
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
              tabs: const [
                Tab(text: 'Gastos'),
                Tab(text: 'Ingresos'),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
          
          const SizedBox(height: AppSizes.lg),
          
          // Resumen del mes
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Gastos',
                  amount: '\$${totalExpenses.toStringAsFixed(2)}',
                  icon: Iconsax.arrow_up_1,
                  color: AppColors.expense,
                  trend: '',
                  isPositive: false,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: _StatCard(
                  title: 'Total Ingresos',
                  amount: '\$${totalIncomes.toStringAsFixed(2)}',
                  icon: Iconsax.arrow_down,
                  color: AppColors.income,
                  trend: '',
                  isPositive: true,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          // Gráfico de pie
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
                Text(
                  selectedType == 'expense' ? 'Distribución de Gastos' : 'Distribución de Ingresos',
                  style: const TextStyle(
                    fontSize: AppSizes.fontLg,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                SizedBox(
                  height: 200,
                  child: PieChart(
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
                            _touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: _generatePieSections(sortedCategories, totalSelected),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                // Leyenda
                _buildLegend(sortedCategories, totalSelected),
              ],
            ),
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: AppSizes.lg),
          
          // Gráfico de barras
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
                const Text(
                  'Últimos 7 días',
                  style: TextStyle(
                    fontSize: AppSizes.fontLg,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 500,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                              return Text(
                                days[value.toInt()],
                                style: const TextStyle(
                                  fontSize: AppSizes.fontSm,
                                  color: AppColors.textSecondary,
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
                      gridData: const FlGridData(show: false),
                      barGroups: _generateBarGroups(selectedTransactions),
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: AppSizes.lg),
          
          // Top categorías
          const SectionHeader(
            title: 'Top Categorías',
            padding: EdgeInsets.only(bottom: AppSizes.md),
          ),
          
          if (sortedCategories.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSizes.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text('No hay datos de gastos'),
              ),
            )
          else
            ...sortedCategories.take(5).map((entry) {
              final category = _categoriesCache[entry.key];
              final percentage = totalSelected > 0 
                  ? (entry.value / totalSelected * 100).toInt() 
                  : 0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: CategoryCard(
                  name: category?.name ?? 'Desconocida',
                  amount: '\$${entry.value.toStringAsFixed(2)}',
                  icon: _getCategoryIcon(category?.icon),
                  color: _getCategoryColor(category?.color),
                  isExpense: selectedType == 'expense',
                  percentage: percentage.toDouble(),
                  animationDelay: sortedCategories.indexOf(entry) * 100,
                ),
              );
            }).toList(),
          
          const SizedBox(height: 120),
        ],
      );
        },
      ),
    );
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

  List<PieChartSectionData> _generatePieSections(List<MapEntry<String, double>> categories, double total) {
    if (categories.isEmpty || total == 0) {
      return [];
    }
    
    final topCategories = categories.take(4).toList();
    
    return topCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final categoryEntry = entry.value;
      final category = _categoriesCache[categoryEntry.key];
      final percentage = (categoryEntry.value / total * 100);
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      
      return PieChartSectionData(
        value: percentage,
        color: _getCategoryColor(category?.color),
        radius: radius,
        title: isTouched ? '${percentage.toInt()}%' : '',
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(List<MapEntry<String, double>> categories, double total) {
    if (categories.isEmpty || total == 0) {
      return const Text('No hay datos', style: TextStyle(color: AppColors.textSecondary));
    }
    
    final topCategories = categories.take(4).toList();

    return Wrap(
      spacing: AppSizes.md,
      runSpacing: AppSizes.sm,
      children: topCategories.map((entry) {
        final category = _categoriesCache[entry.key];
        final percentage = (entry.value / total * 100).toInt();
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getCategoryColor(category?.color),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSizes.xs),
            Text(
              '${category?.name ?? 'Desconocida'} ($percentage%)',
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<BarChartGroupData> _generateBarGroups(List<dynamic> transactions) {
    // Calcular los últimos 7 días
    final now = DateTime.now();
    final dailyTotals = List<double>.filled(7, 0.0);
    
    for (var transaction in transactions) {
      final date = transaction.date;
      final daysDiff = now.difference(date).inDays;
      
      if (daysDiff >= 0 && daysDiff < 7) {
        dailyTotals[6 - daysDiff] += transaction.amount;
      }
    }

    return dailyTotals.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppColors.primary.withOpacity(0.6),
                AppColors.primary,
              ],
            ),
            width: 20,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusSm),
            ),
          ),
        ],
      );
    }).toList();
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final String trend;
  final bool isPositive;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.trend,
    required this.isPositive,
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
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(
                  icon,
                  size: AppSizes.iconSm,
                  color: color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppColors.income.withOpacity(0.1)
                      : AppColors.expense.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: isPositive ? AppColors.income : AppColors.expense,
                    ),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: AppSizes.fontXs,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? AppColors.income : AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            title,
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            amount,
            style: TextStyle(
              fontSize: AppSizes.fontXl,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}
