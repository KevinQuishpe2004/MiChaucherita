import 'package:equatable/equatable.dart';

/// Eventos del BLoC de transacciones
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar transacciones recientes
class LoadRecentTransactions extends TransactionEvent {
  final int limit;

  const LoadRecentTransactions({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

/// Cargar transacciones por rango de fechas
class LoadTransactionsByDateRange extends TransactionEvent {
  final DateTime start;
  final DateTime end;

  const LoadTransactionsByDateRange({
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [start, end];
}

/// Cargar transacciones por cuenta
class LoadTransactionsByAccount extends TransactionEvent {
  final String accountId;

  const LoadTransactionsByAccount(this.accountId);

  @override
  List<Object?> get props => [accountId];
}

/// Crear una nueva transacción (ingreso o gasto)
class CreateTransaction extends TransactionEvent {
  final String type; // 'income' or 'expense'
  final double amount;
  final String accountId;
  final String categoryId;
  final DateTime transactionDate;
  final String? description;

  const CreateTransaction({
    required this.type,
    required this.amount,
    required this.accountId,
    required this.categoryId,
    required this.transactionDate,
    this.description,
  });

  @override
  List<Object?> get props => [
        type,
        amount,
        accountId,
        categoryId,
        transactionDate,
        description,
      ];
}

/// Crear una transferencia
class CreateTransfer extends TransactionEvent {
  final double amount;
  final String fromAccountId;
  final String toAccountId;
  final DateTime transactionDate;
  final String? description;
  final String? notes;

  const CreateTransfer({
    required this.amount,
    required this.fromAccountId,
    required this.toAccountId,
    required this.transactionDate,
    this.description,
    this.notes,
  });

  @override
  List<Object?> get props => [
        amount,
        fromAccountId,
        toAccountId,
        transactionDate,
        description,
        notes,
      ];
}

/// Actualizar una transacción
class UpdateTransaction extends TransactionEvent {
  final String id;
  final String accountId;
  final String categoryId;
  final String type;
  final double amount;
  final DateTime transactionDate;
  final String? description;

  const UpdateTransaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.transactionDate,
    this.description,
  });

  @override
  List<Object?> get props => [
        id,
        accountId,
        categoryId,
        type,
        amount,
        transactionDate,
        description,
      ];
}

/// Eliminar una transacción
class DeleteTransaction extends TransactionEvent {
  final String id;

  const DeleteTransaction(this.id);

  @override
  List<Object?> get props => [id];
}
