import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/models/account.dart';
import '../../../core/data/repositories/account_repository.dart';
import 'account_event.dart';
import 'account_state.dart';

/// BLoC para manejar el estado de las cuentas
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AccountRepository _accountRepository;
  StreamSubscription? _accountsSubscription;

  AccountBloc(this._accountRepository) : super(const AccountInitial()) {
    on<LoadAccounts>(_onLoadAccounts);
    on<CreateAccount>(_onCreateAccount);
    on<UpdateAccount>(_onUpdateAccount);
    on<DeleteAccount>(_onDeleteAccount);
  }

  Future<void> _onLoadAccounts(
    LoadAccounts event,
    Emitter<AccountState> emit,
  ) async {
    emit(const AccountLoading());

    try {
      await _accountsSubscription?.cancel();
      
      await emit.forEach(
        _accountRepository.watchAll(),
        onData: (accounts) {
          // Calcular balance total directamente
          double totalBalance = 0.0;
          for (final account in accounts) {
            totalBalance += account.balance;
          }
          
          return AccountLoaded(
            accounts: accounts,
            totalBalance: totalBalance,
          );
        },
        onError: (error, stackTrace) {
          return AccountError(error.toString());
        },
      );
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onCreateAccount(
    CreateAccount event,
    Emitter<AccountState> emit,
  ) async {
    try {
      final newAccount = Account(
        id: null, // Supabase genera el UUID
        name: event.name,
        type: event.type,
        balance: event.balance,
        currency: 'PEN',
        isActive: true,
        createdAt: DateTime.now(),
      );
      
      final account = await _accountRepository.create(newAccount);
      emit(AccountCreated(account));
      add(const LoadAccounts());
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onUpdateAccount(
    UpdateAccount event,
    Emitter<AccountState> emit,
  ) async {
    try {
      final existingAccount = await _accountRepository.getById(event.id);
      if (existingAccount == null) {
        emit(const AccountError('Cuenta no encontrada'));
        return;
      }
      
      final updatedAccount = existingAccount.copyWith(
        name: event.name,
        type: event.type,
        balance: event.balance,
      );
      
      final account = await _accountRepository.update(updatedAccount);
      emit(AccountUpdated(account));
      add(const LoadAccounts());
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<AccountState> emit,
  ) async {
    try {
      await _accountRepository.delete(event.id);
      emit(AccountDeleted(event.id));
      add(const LoadAccounts());
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _accountsSubscription?.cancel();
    return super.close();
  }
}
