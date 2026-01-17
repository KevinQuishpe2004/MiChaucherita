/// Strings y textos de la aplicación
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'MiChaucherita';
  static const String appTagline = 'Tu compañero de finanzas personales';

  // Navigation
  static const String home = 'Inicio';
  static const String accounts = 'Cuentas';
  static const String statistics = 'Estadísticas';
  static const String settings = 'Ajustes';
  static const String transactions = 'Movimientos';

  // Dashboard
  static const String totalBalance = 'Balance Total';
  static const String monthlyIncome = 'Ingresos del Mes';
  static const String monthlyExpense = 'Gastos del Mes';
  static const String recentTransactions = 'Movimientos Recientes';
  static const String viewAll = 'Ver todo';
  static const String myAccounts = 'Mis Cuentas';
  static const String categories = 'Categorías';

  // Transactions
  static const String income = 'Ingreso';
  static const String expense = 'Egreso';
  static const String transfer = 'Transferencia';
  static const String newTransaction = 'Nuevo Movimiento';
  static const String addIncome = 'Agregar Ingreso';
  static const String addExpense = 'Agregar Egreso';
  static const String makeTransfer = 'Hacer Transferencia';
  static const String amount = 'Monto';
  static const String description = 'Descripción';
  static const String date = 'Fecha';
  static const String category = 'Categoría';
  static const String account = 'Cuenta';
  static const String fromAccount = 'Desde';
  static const String toAccount = 'Hacia';

  // Accounts
  static const String newAccount = 'Nueva Cuenta';
  static const String accountName = 'Nombre de la cuenta';
  static const String initialBalance = 'Saldo inicial';
  static const String selectIcon = 'Seleccionar icono';
  static const String selectColor = 'Seleccionar color';

  // Categories
  static const String newCategory = 'Nueva Categoría';
  static const String categoryName = 'Nombre de la categoría';
  static const String incomeCategories = 'Categorías de Ingreso';
  static const String expenseCategories = 'Categorías de Egreso';

  // Actions
  static const String save = 'Guardar';
  static const String cancel = 'Cancelar';
  static const String delete = 'Eliminar';
  static const String edit = 'Editar';
  static const String confirm = 'Confirmar';
  static const String search = 'Buscar';
  static const String filter = 'Filtrar';

  // Messages
  static const String noTransactions = 'No hay movimientos';
  static const String noAccounts = 'No hay cuentas registradas';
  static const String noCategories = 'No hay categorías';
  static const String confirmDelete = '¿Estás seguro de eliminar?';
  static const String savedSuccessfully = 'Guardado exitosamente';
  static const String errorOccurred = 'Ha ocurrido un error';

  // Currency
  static const String currencySymbol = '\$';
  static const String currencyCode = 'USD';

  // Months
  static const List<String> months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  // Empty States
  static const String emptyDashboard = '¡Comienza agregando tu primera cuenta!';
  static const String emptyTransactions = 'Aún no tienes movimientos registrados';
  static const String emptyAccounts = 'Crea tu primera cuenta para empezar';
}
