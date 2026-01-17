import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/account_bloc.dart';
import '../../bloc/account_event.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({super.key});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  
  String _selectedType = 'bank';
  
  final Map<String, Map<String, dynamic>> _accountTypes = {
    'bank': {
      'label': 'Banco',
      'icon': Icons.account_balance,
      'color': Colors.blue,
    },
    'cash': {
      'label': 'Efectivo',
      'icon': Icons.money,
      'color': Colors.green,
    },
    'credit': {
      'label': 'Tarjeta de Crédito',
      'icon': Icons.credit_card,
      'color': Colors.orange,
    },
    'savings': {
      'label': 'Ahorros',
      'icon': Icons.savings,
      'color': Colors.purple,
    },
    'investment': {
      'label': 'Inversión',
      'icon': Icons.trending_up,
      'color': Colors.teal,
    },
  };

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final balance = double.tryParse(_balanceController.text) ?? 0.0;

    context.read<AccountBloc>().add(
          CreateAccount(
            name: _nameController.text.trim(),
            type: _selectedType,
            balance: balance,
          ),
        );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Cuenta creada correctamente'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Cuenta'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombre de la cuenta
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la cuenta',
                  hintText: 'Ej: BCP Sueldo',
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Tipo de cuenta
              const Text(
                'Tipo de cuenta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _accountTypes.entries.map((entry) {
                  final isSelected = _selectedType == entry.key;
                  final type = entry.value;
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedType = entry.key;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (type['color'] as Color).withOpacity(0.1)
                            : Colors.grey.shade100,
                        border: Border.all(
                          color: isSelected
                              ? type['color'] as Color
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type['icon'] as IconData,
                            color: isSelected
                                ? type['color'] as Color
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? type['color'] as Color
                                  : Colors.grey.shade700,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Balance inicial
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(
                  labelText: 'Balance inicial',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                  helperText: 'Ingresa el saldo actual de esta cuenta',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null; // Balance 0 por defecto
                  }
                  final balance = double.tryParse(value);
                  if (balance == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Botón crear
              FilledButton(
                onPressed: _handleSubmit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _accountTypes[_selectedType]!['color'] as Color,
                ),
                child: const Text(
                  'Crear Cuenta',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Nota
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Puedes crear varias cuentas para organizar mejor tu dinero',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
