import 'package:equatable/equatable.dart';

import '../../../core/domain/models/transaction.dart';

/// Estados del BLoC de transacciones
abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

/// Cargando transacciones
class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

/// Transacciones cargadas exitosamente
class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
  final double totalIncome;
  final double totalExpense;

  const TransactionLoaded({
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
  });

  double get balance => totalIncome - totalExpense;

  @override
  List<Object?> get props => [transactions, totalIncome, totalExpense];
}

/// Error al cargar transacciones
class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Transacción creada exitosamente
class TransactionCreated extends TransactionState {
  final Transaction transaction;

  const TransactionCreated(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Transacción actualizada exitosamente
class TransactionUpdated extends TransactionState {
  final Transaction transaction;

  const TransactionUpdated(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Transacción eliminada exitosamente
class TransactionDeleted extends TransactionState {
  final String transactionId;

  const TransactionDeleted(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}
