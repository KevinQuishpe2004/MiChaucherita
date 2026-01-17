import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/data/repositories/category_repository.dart';
import '../../../../core/domain/models/category.dart';
import '../../../accounts/bloc/account_bloc.dart';
import '../../../accounts/bloc/account_event.dart';
import '../../../accounts/bloc/account_state.dart';
import '../../bloc/transaction_bloc.dart';
import '../../bloc/transaction_event.dart';

/// Página mejorada para agregar/editar transacciones
class AddTransactionPage extends StatefulWidget {
  final String transactionType;
  final String? preselectedAccountId;

  const AddTransactionPage({
    super.key,
    required this.transactionType,
    this.preselectedAccountId,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage>
    with TickerProviderStateMixin {
  late String _type;
  late TabController _tabController;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedAccount;
  String? _selectedCategory;
  String? _selectedCategoryId; // Guardar el UUID de la categoría
  String? _selectedToAccount;
  bool _isRecurring = false;
  String _recurringFrequency = 'monthly';
  
  // Repositorio de categorías
  final CategoryRepository _categoryRepository = CategoryRepository();
  List<Category> _categories = [];
  bool _isLoadingCategories = true;

  final List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _accountsFromBloc = [];
  
  // Mapeo de nombres de iconos a IconData
  final Map<String, IconData> _iconMap = {
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
  
  IconData _getIconData(String? iconName) {
    if (iconName == null) return Iconsax.more_circle;
    return _iconMap[iconName] ?? Iconsax.more_circle;
  }
  
  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null) return Colors.grey;
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  void initState() {
    super.initState();
    _type = widget.transactionType;
    _selectedAccount = widget.preselectedAccountId;
    _tabController = TabController(
      length: 3, 
      vsync: this,
      initialIndex: _type == 'income' ? 0 : (_type == 'expense' ? 1 : 2),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _type = ['income', 'expense', 'transfer'][_tabController.index];
          _selectedCategory = null;
          _selectedCategoryId = null;
          _loadCategories(); // Recargar categorías al cambiar tab
        });
      }
    });
    
    // Cargar cuentas y categorías al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountBloc>().add(const LoadAccounts());
      _loadCategories();
    });
  }
  
  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await _categoryRepository.getByType(_type);
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar categorías: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Color get _typeColor {
    switch (_type) {
      case 'income':
        return AppColors.income;
      case 'expense':
        return AppColors.expense;
      case 'transfer':
        return AppColors.transfer;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state is AccountLoaded) {
          setState(() {
            _accountsFromBloc = state.accounts.map((account) => {
              'id': account.id,
              'name': account.name,
              'icon': _getAccountIcon(account.type),
              'color': _getAccountColor(account.type),
              'balance': account.balance,
            }).toList();
          });
        }
      },
      child: Scaffold(
        backgroundColor: _typeColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header con monto
              _buildHeader(),
              // Contenido scrolleable
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tabs de tipo
                        _buildTypeTabs(),
                        const SizedBox(height: AppSizes.xl),
                        // Contenido según el tipo
                        if (_type == 'transfer')
                          _buildTransferForm()
                        else
                          _buildTransactionForm(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        children: [
          // Barra superior
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                _type == 'income' ? 'Nuevo Ingreso' 
                    : _type == 'expense' ? 'Nuevo Egreso' 
                    : 'Nueva Transferencia',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: _saveTransaction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Text(
                    'Guardar',
                    style: TextStyle(
                      color: _typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xl),
          // Monto grande
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '\$',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 100),
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            color: Colors.white38,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          isDense: true,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
              const SizedBox(height: AppSizes.sm),
              // Fecha y hora
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.calendar_1,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppSizes.fontSm,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Container(
                        width: 1,
                        height: 14,
                        color: Colors.white30,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      GestureDetector(
                        onTap: _selectTime,
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.clock,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: AppSizes.xs),
                            Text(
                              _formatTime(_selectedTime),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: AppSizes.fontSm,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 200.ms).fadeIn().scale(begin: const Offset(0.9, 0.9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _typeColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          boxShadow: [
            BoxShadow(
              color: _typeColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: AppSizes.fontSm,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.arrow_down, size: 18),
                const SizedBox(width: 6),
                const Text('Ingreso'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.arrow_up_1, size: 18),
                const SizedBox(width: 6),
                const Text('Egreso'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.arrow_swap_horizontal, size: 18),
                const SizedBox(width: 6),
                const Text('Transfer'),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildTransactionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección de cuenta
        _buildSectionTitle('Cuenta', Iconsax.wallet_3),
        const SizedBox(height: AppSizes.sm),
        _buildAccountSelector(),
        
        const SizedBox(height: AppSizes.xl),
        
        // Sección de categoría
        _buildSectionTitle('Categoría', Iconsax.category),
        const SizedBox(height: AppSizes.sm),
        _buildCategoryGrid(),
        
        const SizedBox(height: AppSizes.xl),
        
        // Descripción
        _buildSectionTitle('Descripción', Iconsax.document_text),
        const SizedBox(height: AppSizes.sm),
        _buildDescriptionField(),
        
        const SizedBox(height: AppSizes.xl),
        
        // Opciones adicionales
        _buildAdditionalOptions(),
        
        const SizedBox(height: AppSizes.xl),
        
        // Botón guardar
        _buildSaveButton(),
        
        const SizedBox(height: AppSizes.lg),
      ],
    );
  }

  Widget _buildTransferForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Desde cuenta
        _buildSectionTitle('Desde', Iconsax.export_1),
        const SizedBox(height: AppSizes.sm),
        _buildAccountSelector(isFrom: true),
        
        const SizedBox(height: AppSizes.lg),
        
        // Ícono de transferencia
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.transfer.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.arrow_down,
              color: AppColors.transfer,
              size: 28,
            ),
          ),
        ).animate().scale(delay: 200.ms),
        
        const SizedBox(height: AppSizes.lg),
        
        // Hacia cuenta
        _buildSectionTitle('Hacia', Iconsax.import_1),
        const SizedBox(height: AppSizes.sm),
        _buildAccountSelector(isFrom: false, isTo: true),
        
        const SizedBox(height: AppSizes.xl),
        
        // Descripción
        _buildSectionTitle('Nota (opcional)', Iconsax.document_text),
        const SizedBox(height: AppSizes.sm),
        _buildDescriptionField(),
        
        const SizedBox(height: AppSizes.xl),
        
        // Botón guardar
        _buildSaveButton(),
        
        const SizedBox(height: AppSizes.lg),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.sm),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppSizes.fontMd,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSelector({bool isFrom = false, bool isTo = false}) {
    final selectedValue = isTo ? _selectedToAccount : _selectedAccount;
    final accounts = _accountsFromBloc.isNotEmpty ? _accountsFromBloc : _accounts;
    
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.sm),
        itemBuilder: (context, index) {
          final account = accounts[index];
          final isSelected = selectedValue == account['name'];
          
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (isTo) {
                  _selectedToAccount = account['name'];
                } else {
                  _selectedAccount = account['name'];
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 140,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (account['color'] as Color).withOpacity(0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(
                  color: isSelected 
                      ? account['color'] as Color
                      : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (account['color'] as Color).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          account['icon'] as IconData,
                          size: 16,
                          color: account['color'] as Color,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: account['color'] as Color,
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account['name'] as String,
                        style: TextStyle(
                          fontSize: AppSizes.fontSm,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? account['color'] as Color
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '\$${(account['balance'] as double).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().slideX(begin: 0.1);
        },
      ),
    );
  }

  Widget _buildCategoryGrid() {
    if (_isLoadingCategories) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_categories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No hay categorías disponibles'),
        ),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSizes.sm,
        crossAxisSpacing: AppSizes.sm,
        childAspectRatio: 0.85,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final isSelected = _selectedCategoryId == category.id;
        final color = _getColorFromHex(category.color);
        final icon = _getIconData(category.icon);
        
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedCategory = category.name;
              _selectedCategoryId = category.id;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected 
                  ? color.withOpacity(0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: isSelected 
                    ? color
                    : Colors.transparent,
                width: isSelected ? 2 : 0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isSelected ? 0.3 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? color
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 30 * index)).fadeIn().scale(begin: const Offset(0.8, 0.8));
      },
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _descriptionController,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: _type == 'transfer' 
              ? 'Agrega una nota...' 
              : '¿En qué lo usaste?',
          hintStyle: const TextStyle(color: AppColors.textHint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppSizes.md),
        ),
      ),
    );
  }

  Widget _buildAdditionalOptions() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Opción de recurrente
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.repeat,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Movimiento recurrente',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Se repetirá automáticamente',
                      style: TextStyle(
                        fontSize: AppSizes.fontXs,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isRecurring,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() => _isRecurring = value);
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
          
          // Frecuencia (si es recurrente)
          if (_isRecurring) ...[
            const Divider(height: AppSizes.xl),
            Row(
              children: [
                const Text(
                  'Frecuencia:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFrequencyChip('Diario', 'daily'),
                        const SizedBox(width: AppSizes.sm),
                        _buildFrequencyChip('Semanal', 'weekly'),
                        const SizedBox(width: AppSizes.sm),
                        _buildFrequencyChip('Mensual', 'monthly'),
                        const SizedBox(width: AppSizes.sm),
                        _buildFrequencyChip('Anual', 'yearly'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate(delay: 300.ms).fadeIn();
  }

  Widget _buildFrequencyChip(String label, String value) {
    final isSelected = _recurringFrequency == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _recurringFrequency = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? _typeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: isSelected ? _typeColor : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: _typeColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _type == 'transfer' ? Iconsax.arrow_swap_horizontal : Iconsax.tick_circle,
              size: 22,
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              _type == 'transfer' ? 'Realizar Transferencia' : 'Guardar ${_type == 'income' ? 'Ingreso' : 'Egreso'}',
              style: const TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Hoy';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Ayer';
    }
    
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _typeColor,
              onPrimary: Colors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _typeColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveTransaction() {
    // Validaciones
    if (_amountController.text.isEmpty) {
      _showSnackBar('Ingresa un monto');
      return;
    }
    
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar('Ingresa un monto válido');
      return;
    }
    
    if (_selectedAccount == null) {
      _showSnackBar('Selecciona una cuenta');
      return;
    }
    
    if (_type != 'transfer' && _selectedCategory == null) {
      _showSnackBar('Selecciona una categoría');
      return;
    }
    
    if (_type == 'transfer' && _selectedToAccount == null) {
      _showSnackBar('Selecciona la cuenta destino');
      return;
    }
    
    if (_type == 'transfer' && _selectedAccount == _selectedToAccount) {
      _showSnackBar('Las cuentas deben ser diferentes');
      return;
    }

    // Buscar IDs de las cuentas
    final accountId = _accountsFromBloc.firstWhere(
      (acc) => acc['name'] == _selectedAccount,
      orElse: () => {},
    )['id'] as String?;

    if (accountId == null) {
      _showSnackBar('Error: cuenta no encontrada');
      return;
    }

    final transactionDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    HapticFeedback.mediumImpact();
    
    if (_type == 'transfer') {
      final toAccountId = _accountsFromBloc.firstWhere(
        (acc) => acc['name'] == _selectedToAccount,
        orElse: () => {},
      )['id'] as String?;

      if (toAccountId == null) {
        _showSnackBar('Error: cuenta destino no encontrada');
        return;
      }

      context.read<TransactionBloc>().add(
        CreateTransfer(
          amount: amount,
          fromAccountId: accountId,
          toAccountId: toAccountId,
          transactionDate: transactionDate,
          description: _descriptionController.text.isEmpty 
              ? null 
              : _descriptionController.text,
          notes: _notesController.text.isEmpty 
              ? null 
              : _notesController.text,
        ),
      );
    } else {
      // Validar que se haya seleccionado una categoría
      if (_selectedCategoryId == null) {
        _showSnackBar('Selecciona una categoría');
        return;
      }

      // Usar nombre de categoría como descripción por defecto si no hay descripción
      String description = _descriptionController.text.isEmpty 
          ? (_selectedCategory ?? 'Transacción')
          : _descriptionController.text;

      context.read<TransactionBloc>().add(
        CreateTransaction(
          type: _type,
          amount: amount,
          accountId: accountId,
          categoryId: _selectedCategoryId!,
          transactionDate: transactionDate,
          description: description,
        ),
      );
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              _type == 'transfer' 
                  ? '¡Transferencia realizada!'
                  : _type == 'income' 
                      ? '¡Ingreso registrado!'
                      : '¡Egreso registrado!',
            ),
          ],
        ),
        backgroundColor: _typeColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
    );
    
    context.pop();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.expense,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
    );
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
