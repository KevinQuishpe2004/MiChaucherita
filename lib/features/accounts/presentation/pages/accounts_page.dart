import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/data/repositories/transaction_repository.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/router/app_router.dart';
import '../../bloc/account_bloc.dart';
import '../../bloc/account_event.dart';
import '../../bloc/account_state.dart';

IconData _getAccountIconForPage(String type) {
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

Color _getAccountColorForPage(String type) {
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

/// Página de cuentas
class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final TransactionRepository _transactionRepository = TransactionRepository();
  final Map<String, int> _transactionCounts = {};

  Future<void> _loadTransactionCount(String accountId) async {
    final count = await _transactionRepository.countByAccount(accountId);
    if (mounted) {
      setState(() {
        _transactionCounts[accountId] = count;
      });
    }
  }

  void _showAddTransactionDialog(BuildContext context, String accountId, String type) {
    // Navegar directamente a la página de agregar transacción
    context.push('/add-transaction', extra: {
      'type': type,
      'accountId': accountId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.accounts),
        actions: [
          IconButton(
            onPressed: () {
              context.push(AppRoutes.addAccount);
            },
            icon: const Icon(Iconsax.add_circle),
            tooltip: 'Nueva Cuenta',
          ),
        ],
      ),
      body: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          if (state is AccountLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is AccountError) {
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
                    'Error al cargar cuentas',
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
                      context.read<AccountBloc>().add(LoadAccounts());
                    },
                    icon: const Icon(Iconsax.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is AccountLoaded) {
            final accounts = state.accounts;
            
            if (accounts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Iconsax.empty_wallet,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      'No hay cuentas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    const Text(
                      'Agrega tu primera cuenta para comenzar',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    FilledButton.icon(
                      onPressed: () {
                        context.push(AppRoutes.addAccount);
                      },
                      icon: const Icon(Iconsax.add),
                      label: const Text('Crear Cuenta'),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppSizes.md),
              children: [
                // Tarjeta de balance total
                _TotalBalanceCard(
                  totalBalance: '\$${state.totalBalance.toStringAsFixed(2)}',
                  accountCount: accounts.length,
                ),
                
                const SizedBox(height: AppSizes.lg),
                
                // Lista de cuentas
                const SectionHeader(
                  title: 'Mis Cuentas',
                  padding: EdgeInsets.only(bottom: AppSizes.md),
                ),
                
                ...accounts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final account = entry.value;
                  
                  // Cargar conteo de transacciones si no está cargado
                  if (account.id != null && !_transactionCounts.containsKey(account.id!)) {
                    _loadTransactionCount(account.id!);
                  }
                  
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < accounts.length - 1 ? AppSizes.md : 0,
                    ),
                    child: AccountCardLarge(
                      name: account.name,
                      balance: '\$${account.balance.toStringAsFixed(2)}',
                      icon: _getAccountIconForPage(account.type),
                      color: _getAccountColorForPage(account.type),
                      transactionCount: _transactionCounts[account.id] ?? 0,
                      animationDelay: index * 100,
                      onTap: () {
                        // TODO: Navegar a detalles de cuenta
                      },
                      onAddIncome: () {
                        if (account.id != null) {
                          _showAddTransactionDialog(context, account.id!, 'income');
                        }
                      },
                      onAddExpense: () {
                        if (account.id != null) {
                          _showAddTransactionDialog(context, account.id!, 'expense');
                        }
                      },
                    ),
                  );
                }),
                
                const SizedBox(height: AppSizes.lg),
                
                // Botón de agregar cuenta
                _AddAccountButton(
                  onTap: () {
                    context.push(AppRoutes.addAccount);
                  },
                ),
                
                const SizedBox(height: 120),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'bank':
        return Iconsax.bank;
      case 'wallet':
      case 'wallet_1':
        return Iconsax.wallet_1;
      case 'money':
        return Iconsax.money;
      case 'card':
        return Iconsax.card;
      case 'safe_home':
      case 'save_2':
        return Iconsax.safe_home;
      default:
        return Iconsax.wallet_3;
    }
  }

  Color _getColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }
}

class _TotalBalanceCard extends StatelessWidget {
  final String totalBalance;
  final int accountCount;

  const _TotalBalanceCard({
    required this.totalBalance,
    required this.accountCount,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(
                  Iconsax.wallet_3,
                  color: Colors.white,
                  size: AppSizes.iconMd,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance Total',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: AppSizes.fontSm,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            totalBalance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Text(
              '$accountCount cuentas activas',
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppSizes.fontSm,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _AddAccountButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddAccountButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.add,
                  color: Colors.white,
                  size: AppSizes.iconMd,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              const Text(
                'Agregar Nueva Cuenta',
                style: TextStyle(
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }
}
