import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/models/transaction.dart';
import '../../../core/data/repositories/transaction_repository.dart';
import '../../../core/data/repositories/category_repository.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

/// BLoC para manejar el estado de las transacciones
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository = CategoryRepository();
  StreamSubscription? _transactionsSubscription;

  TransactionBloc(this._transactionRepository) : super(const TransactionInitial()) {
    on<LoadRecentTransactions>(_onLoadRecentTransactions);
    on<LoadTransactionsByDateRange>(_onLoadTransactionsByDateRange);
    on<LoadTransactionsByAccount>(_onLoadTransactionsByAccount);
    on<CreateTransaction>(_onCreateTransaction);
    on<CreateTransfer>(_onCreateTransfer);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
  }

  Future<void> _onLoadRecentTransactions(
    LoadRecentTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());

    try {
      await _transactionsSubscription?.cancel();
      
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      await emit.forEach(
        _transactionRepository.watchRecent(limit: event.limit),
        onData: (transactions) {
          // Calcular totales basados en las transacciones cargadas
          double totalIncome = 0.0;
          double totalExpense = 0.0;

          for (final transaction in transactions) {
            if (transaction.date.isAfter(firstDayOfMonth) &&
                transaction.date.isBefore(lastDayOfMonth)) {
              if (transaction.type == 'income') {
                totalIncome += transaction.amount;
              } else if (transaction.type == 'expense') {
                totalExpense += transaction.amount;
              }
            }
          }

          return TransactionLoaded(
            transactions: transactions,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
          );
        },
        onError: (error, stackTrace) {
          return TransactionError(error.toString());
        },
      );
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onLoadTransactionsByDateRange(
    LoadTransactionsByDateRange event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());

    try {
      await _transactionsSubscription?.cancel();
      
      await emit.forEach(
        _transactionRepository.watchByDateRange(event.start, event.end),
        onData: (transactions) {
          double totalIncome = 0.0;
          double totalExpense = 0.0;

          for (final transaction in transactions) {
            if (transaction.type == 'income') {
              totalIncome += transaction.amount;
            } else if (transaction.type == 'expense') {
              totalExpense += transaction.amount;
            }
          }

          return TransactionLoaded(
            transactions: transactions,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
          );
        },
        onError: (error, stackTrace) {
          return TransactionError(error.toString());
        },
      );
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onLoadTransactionsByAccount(
    LoadTransactionsByAccount event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());

    try {
      await _transactionsSubscription?.cancel();
      
      await emit.forEach(
        _transactionRepository.watchByAccount(event.accountId),
        onData: (transactions) {
          double totalIncome = 0.0;
          double totalExpense = 0.0;

          for (final transaction in transactions) {
            if (transaction.type == 'income') {
              totalIncome += transaction.amount;
            } else if (transaction.type == 'expense') {
              totalExpense += transaction.amount;
            }
          }

          return TransactionLoaded(
            transactions: transactions,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
          );
        },
        onError: (error, stackTrace) {
          return TransactionError(error.toString());
        },
      );
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onCreateTransaction(
    CreateTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      final transaction = Transaction(
        id: null,
        accountId: event.accountId,
        categoryId: event.categoryId,
        type: event.type,
        amount: event.amount,
        description: event.description ?? '',
        date: event.transactionDate,
        createdAt: DateTime.now(),
      );
      
      await _transactionRepository.create(transaction);

      // Recargar las transacciones recientes - esto emitirá el nuevo estado
      final transactions = await _transactionRepository.getRecent(limit: 50);
      final totalIncome = transactions.where((t) => t.type == 'income').fold<double>(0, (sum, t) => sum + t.amount);
      final totalExpense = transactions.where((t) => t.type == 'expense').fold<double>(0, (sum, t) => sum + t.amount);
      emit(TransactionLoaded(
        transactions: transactions,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
      ));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onCreateTransfer(
    CreateTransfer event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      // Obtener la categoría de transferencia o usar una por defecto
      final categories = await _categoryRepository.getAll();
      // Buscar una categoría específica para transferencias, o usar la primera disponible
      final transferCategory = categories.firstWhere(
        (c) => c.name.toLowerCase().contains('transfer') || c.name.toLowerCase().contains('otros'),
        orElse: () => categories.first,
      );
      
      // Crear una sola transacción de tipo 'transfer'
      // El monto se resta de la cuenta origen y se suma a la cuenta destino
      final transfer = Transaction(
        id: null,
        accountId: event.fromAccountId,
        categoryId: transferCategory.id,
        type: 'transfer',
        amount: event.amount,
        description: event.description ?? 'Transferencia entre cuentas',
        date: event.transactionDate,
        createdAt: DateTime.now(),
      );
      
      // Crear la transacción de transferencia
      await _transactionRepository.create(transfer);
      
      // Actualizar el balance de la cuenta destino manualmente
      // La cuenta origen se actualiza automáticamente en el repositorio
      await _transactionRepository.updateAccountBalanceForTransfer(
        event.toAccountId,
        event.amount,
      );

      // Recargar las transacciones recientes
      add(const LoadRecentTransactions());
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      final updatedTransaction = Transaction(
        id: event.id,
        accountId: event.accountId,
        categoryId: event.categoryId,
        type: event.type,
        amount: event.amount,
        description: event.description,
        date: event.transactionDate,
        createdAt: DateTime.now(),
      );
      
      await _transactionRepository.update(updatedTransaction);
      add(const LoadRecentTransactions());
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _transactionRepository.delete(event.id);
      emit(TransactionDeleted(event.id));
      add(const LoadRecentTransactions());
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }
}
