import 'package:equatable/equatable.dart';

/// Eventos del BLoC de cuentas
abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar todas las cuentas
class LoadAccounts extends AccountEvent {
  const LoadAccounts();
}

/// Crear una nueva cuenta
class CreateAccount extends AccountEvent {
  final String name;
  final String type;
  final double balance;

  const CreateAccount({
    required this.name,
    required this.type,
    required this.balance,
  });

  @override
  List<Object?> get props => [name, type, balance];
}

/// Actualizar una cuenta
class UpdateAccount extends AccountEvent {
  final String id;
  final String? name;
  final String? type;
  final double? balance;

  const UpdateAccount({
    required this.id,
    this.name,
    this.type,
    this.balance,
  });

  @override
  List<Object?> get props => [id, name, type, balance];
}

/// Eliminar una cuenta
class DeleteAccount extends AccountEvent {
  final String id;

  const DeleteAccount(this.id);

  @override
  List<Object?> get props => [id];
}
