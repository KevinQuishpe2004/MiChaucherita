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
      // Obtener una categoría por defecto (usamos la primera de ingresos)
      final categories = await _categoryRepository.getByType('income');
      if (categories.isEmpty) {
        emit(const TransactionError('No hay categorías disponibles'));
        return;
      }
      final defaultCategoryId = categories.first.id;
      
      // Crear dos transacciones: gasto de origen, ingreso a destino
      final expense = Transaction(
        id: null,
        accountId: event.fromAccountId,
        categoryId: defaultCategoryId,
        type: 'expense',
        amount: event.amount,
        description: event.description ?? 'Transferencia',
        date: event.transactionDate,
        createdAt: DateTime.now(),
      );
      
      final income = Transaction(
        id: null,
        accountId: event.toAccountId,
        categoryId: defaultCategoryId,
        type: 'income',
        amount: event.amount,
        description: event.description ?? 'Transferencia',
        date: event.transactionDate,
        createdAt: DateTime.now(),
      );
      
      await _transactionRepository.create(expense);
      await _transactionRepository.create(income);

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
