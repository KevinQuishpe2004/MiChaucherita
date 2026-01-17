import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

/// Filtro de transacciones
class TransactionFilter extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const TransactionFilter({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'Todos',
            value: 'all',
            isSelected: selectedFilter == 'all',
            onTap: () => onFilterChanged('all'),
          ),
          const SizedBox(width: AppSizes.sm),
          _FilterChip(
            label: 'Ingresos',
            value: 'income',
            isSelected: selectedFilter == 'income',
            color: AppColors.income,
            onTap: () => onFilterChanged('income'),
          ),
          const SizedBox(width: AppSizes.sm),
          _FilterChip(
            label: 'Egresos',
            value: 'expense',
            isSelected: selectedFilter == 'expense',
            color: AppColors.expense,
            onTap: () => onFilterChanged('expense'),
          ),
          const SizedBox(width: AppSizes.sm),
          _FilterChip(
            label: 'Transferencias',
            value: 'transfer',
            isSelected: selectedFilter == 'transfer',
            color: AppColors.transfer,
            onTap: () => onFilterChanged('transfer'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : chipColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: isSelected ? chipColor : chipColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : chipColor,
            ),
          ),
        ),
      ),
    );
  }
}
