import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/data/repositories/category_repository.dart';
import '../../../../core/domain/models/category.dart';
import '../../../../core/widgets/widgets.dart';
import '../../bloc/transaction_bloc.dart';
import '../../bloc/transaction_event.dart';
import '../../bloc/transaction_state.dart';
import '../widgets/transaction_filter.dart';

/// Página de lista de transacciones
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _selectedFilter = 'all';
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
      // Silently fail
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

  void _applyFilter() {
    setState(() {
      // setState will trigger rebuild with current _selectedFilter
    });
  }

  List<dynamic> _filterTransactions(List<dynamic> transactions) {
    if (_selectedFilter == 'all') {
      return transactions;
    }
    return transactions.where((t) => t.type == _selectedFilter).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.transactions),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implementar búsqueda
            },
            icon: const Icon(Iconsax.search_normal_1),
          ),
          IconButton(
            onPressed: () {
              // TODO: Implementar filtros avanzados
            },
            icon: const Icon(Iconsax.filter),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          TransactionFilter(
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              setState(() => _selectedFilter = filter);
              // Aplicar filtrado
              _applyFilter();
            },
          ),
          
          // Lista de transacciones
          Expanded(
            child: BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is TransactionError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Iconsax.danger,
                          size: 64,
                          color: AppColors.expense,
                        ),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          'Error al cargar transacciones',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          state.message,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.lg),
                        FilledButton.icon(
                          onPressed: () {
                            context.read<TransactionBloc>().add(
                              LoadRecentTransactions(limit: 20),
                            );
                          },
                          icon: const Icon(Iconsax.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is TransactionLoaded) {
                  final transactions = _filterTransactions(state.transactions);
                  
                  if (transactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Iconsax.receipt_minus,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSizes.md),
                          Text(
                            'No hay transacciones',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSizes.sm),
                          const Text(
                            'Agrega tu primera transacción',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  // Agrupar transacciones por fecha
                  final groupedTransactions = _groupTransactionsByDate(transactions);

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.md),
                    itemCount: groupedTransactions.length + 1, // +1 para el espacio final
                    itemBuilder: (context, index) {
                      if (index == groupedTransactions.length) {
                        return const SizedBox(height: 120);
                      }

                      final entry = groupedTransactions.entries.elementAt(index);
                      final date = entry.key;
                      final dayTransactions = entry.value;

                      return _DateGroup(
                        date: date,
                        children: dayTransactions.asMap().entries.map((e) {
                          final idx = e.key;
                          final transaction = e.value;
                          
                          final category = _getCategoryById(transaction.categoryId);
                          return Column(
                            children: [
                              if (idx > 0) const Divider(height: 1, indent: 72),
                              TransactionTile(
                                title: transaction.description ?? 'Sin descripción',
                                category: category?.name ?? 'General',
                                amount: '\$${transaction.amount.toStringAsFixed(2)}',
                                date: DateFormat('HH:mm').format(transaction.date),
                                type: _mapTransactionType(transaction.type),
                                categoryIcon: _getCategoryIcon(category?.icon),
                                categoryColor: _getCategoryColor(category?.color),
                                animationDelay: index * 50 + idx * 25,
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<dynamic>> _groupTransactionsByDate(List<dynamic> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    final Map<String, List<dynamic>> grouped = {};

    for (var transaction in transactions) {
      final transactionDate = transaction.date;
      final date = DateTime(
        transactionDate.year,
        transactionDate.month,
        transactionDate.day,
      );

      String dateKey;
      if (date == today) {
        dateKey = 'Hoy';
      } else if (date == yesterday) {
        dateKey = 'Ayer';
      } else {
        dateKey = DateFormat('d \'de\' MMMM', 'es').format(date);
      }

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(transaction);
    }

    return grouped;
  }

  TransactionType _mapTransactionType(dynamic type) {
    final typeString = type.toString();
    if (typeString.contains('income')) return TransactionType.income;
    if (typeString.contains('expense')) return TransactionType.expense;
    return TransactionType.transfer;
  }
}

class _DateGroup extends StatelessWidget {
  final String date;
  final List<Widget> children;

  const _DateGroup({
    required this.date,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.sm,
          ),
          child: Text(
            date,
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
          child: Column(children: children),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: AppSizes.md),
      ],
    );
  }
}
