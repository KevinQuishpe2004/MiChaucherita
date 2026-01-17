import 'package:equatable/equatable.dart';

import '../../../core/domain/models/account.dart';

/// Estados del BLoC de cuentas
abstract class AccountState extends Equatable {
  const AccountState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class AccountInitial extends AccountState {
  const AccountInitial();
}

/// Cargando cuentas
class AccountLoading extends AccountState {
  const AccountLoading();
}

/// Cuentas cargadas exitosamente
class AccountLoaded extends AccountState {
  final List<Account> accounts;
  final double totalBalance;

  const AccountLoaded({
    required this.accounts,
    required this.totalBalance,
  });

  @override
  List<Object?> get props => [accounts, totalBalance];
}

/// Error al cargar cuentas
class AccountError extends AccountState {
  final String message;

  const AccountError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Cuenta creada exitosamente
class AccountCreated extends AccountState {
  final Account account;

  const AccountCreated(this.account);

  @override
  List<Object?> get props => [account];
}

/// Cuenta actualizada exitosamente
class AccountUpdated extends AccountState {
  final Account account;

  const AccountUpdated(this.account);

  @override
  List<Object?> get props => [account];
}

/// Cuenta eliminada exitosamente
class AccountDeleted extends AccountState {
  final String accountId;

  const AccountDeleted(this.accountId);

  @override
  List<Object?> get props => [accountId];
}
