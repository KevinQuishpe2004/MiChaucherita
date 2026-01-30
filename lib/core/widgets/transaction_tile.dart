import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

enum TransactionType { income, expense, transfer }

/// Tile de transacción para mostrar en listas
class TransactionTile extends StatelessWidget {
  final String title;
  final String category;
  final String amount;
  final String date;
  final TransactionType type;
  final IconData categoryIcon;
  final Color categoryColor;
  final VoidCallback? onTap;
  final int animationDelay;
  final String? accountName;
  final String? toAccountName; // Para transferencias

  const TransactionTile({
    super.key,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    this.categoryIcon = Icons.category,
    this.categoryColor = AppColors.primary,
    this.onTap,
    this.animationDelay = 0,
    this.accountName,
    this.toAccountName,
  });

  void _showTransactionDetails(BuildContext context) {
    final isIncome = type == TransactionType.income;
    final isTransfer = type == TransactionType.transfer;
    
    final amountColor = isTransfer 
        ? AppColors.transfer 
        : (isIncome ? AppColors.income : AppColors.expense);
    
    final amountPrefix = isTransfer ? '' : (isIncome ? '+' : '-');
    
    String typeLabel;
    IconData typeIcon;
    if (isIncome) {
      typeLabel = 'Ingreso';
      typeIcon = Iconsax.arrow_down;
    } else if (isTransfer) {
      typeLabel = 'Transferencia';
      typeIcon = Icons.swap_horiz;
    } else {
      typeLabel = 'Egreso';
      typeIcon = Iconsax.arrow_up_1;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
        ),
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            
            // Icono y tipo
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(typeIcon, size: 16, color: amountColor),
                          const SizedBox(width: 4),
                          Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: AppSizes.fontSm,
                              fontWeight: FontWeight.w500,
                              color: amountColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$amountPrefix$amount',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSizes.lg),
            const Divider(),
            const SizedBox(height: AppSizes.md),
            
            // Descripción completa
            _DetailRow(
              icon: Iconsax.document_text,
              label: 'Descripción',
              value: title,
              isMultiline: true,
            ),
            
            const SizedBox(height: AppSizes.md),
            
            // Categoría
            _DetailRow(
              icon: Iconsax.category,
              label: 'Categoría',
              value: category,
              valueColor: categoryColor,
            ),
            
            const SizedBox(height: AppSizes.md),
            
            // Fecha
            _DetailRow(
              icon: Iconsax.calendar_1,
              label: 'Fecha',
              value: date,
            ),
            
            // Cuenta
            if (accountName != null) ...[
              const SizedBox(height: AppSizes.md),
              _DetailRow(
                icon: Iconsax.wallet_3,
                label: isTransfer ? 'Desde cuenta' : 'Cuenta',
                value: accountName!,
              ),
            ],
            
            // Cuenta destino (transferencias)
            if (isTransfer && toAccountName != null) ...[
              const SizedBox(height: AppSizes.md),
              _DetailRow(
                icon: Iconsax.wallet_check,
                label: 'Hacia cuenta',
                value: toAccountName!,
              ),
            ],
            
            const SizedBox(height: AppSizes.xl),
            
            // Botón cerrar
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                ),
                child: const Text('Cerrar'),
              ),
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = type == TransactionType.income;
    final isTransfer = type == TransactionType.transfer;
    final isExpense = type == TransactionType.expense;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final amountColor = isTransfer 
        ? AppColors.transfer 
        : (isIncome ? AppColors.income : AppColors.expense);
    
    final amountPrefix = isTransfer ? '' : (isIncome ? '+' : '-');
    
    // Colores de texto que se adaptan al tema
    final textPrimaryColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => _showTransactionDetails(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.md,
          ),
          child: Row(
            children: [
              // Icono de categoría
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(
                  categoryIcon,
                  color: categoryColor,
                  size: AppSizes.iconMd,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AppSizes.fontMd,
                        fontWeight: FontWeight.w600,
                        color: textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: AppSizes.fontXs,
                              fontWeight: FontWeight.w500,
                              color: categoryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: AppSizes.fontSm,
                            color: textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    // Mostrar información de cuenta
                    if (accountName != null) ...[
                      const SizedBox(height: AppSizes.xs),
                      Row(
                        children: [
                          Icon(
                            Iconsax.wallet_3,
                            size: 12,
                            color: textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isTransfer && toAccountName != null
                                ? '$accountName → $toAccountName'
                                : accountName!,
                            style: TextStyle(
                              fontSize: AppSizes.fontXs,
                              color: textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Monto y etiqueta de tipo
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amountPrefix$amount',
                    style: TextStyle(
                      fontSize: AppSizes.fontLg,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  // Etiqueta de tipo para TODOS los tipos
                  _buildTypeLabel(isIncome, isExpense, isTransfer),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }
  
  Widget _buildTypeLabel(bool isIncome, bool isExpense, bool isTransfer) {
    IconData icon;
    String label;
    Color color;
    
    if (isIncome) {
      icon = Iconsax.arrow_down;
      label = 'Ingreso';
      color = AppColors.income;
    } else if (isExpense) {
      icon = Iconsax.arrow_up_1;
      label = 'Egreso';
      color = AppColors.expense;
    } else {
      icon = Icons.swap_horiz;
      label = 'Transferencia';
      color = AppColors.transfer;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppSizes.iconXs,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.fontXs,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar una fila de detalle
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isMultiline;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppSizes.fontXs,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
