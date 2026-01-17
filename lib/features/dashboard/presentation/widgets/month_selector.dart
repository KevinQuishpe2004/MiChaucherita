import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

/// Selector de mes para filtrar datos
class MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  void _previousMonth() {
    onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month - 1));
  }

  void _nextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    if (nextMonth.isBefore(now) || 
        (nextMonth.year == now.year && nextMonth.month == now.month)) {
      onMonthChanged(nextMonth);
    }
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return selectedMonth.year < now.year ||
        (selectedMonth.year == now.year && selectedMonth.month < now.month);
  }

  String get _monthYearText {
    final monthName = AppStrings.months[selectedMonth.month - 1];
    return '$monthName ${selectedMonth.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ArrowButton(
              icon: Iconsax.arrow_left_2,
              onTap: _previousMonth,
            ),
            GestureDetector(
              onTap: () => _showMonthPicker(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Iconsax.calendar_1,
                    color: AppColors.primary,
                    size: AppSizes.iconSm,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    _monthYearText,
                    style: const TextStyle(
                      fontSize: AppSizes.fontMd,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            _ArrowButton(
              icon: Iconsax.arrow_right_3,
              onTap: _canGoNext ? _nextMonth : null,
              enabled: _canGoNext,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  void _showMonthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MonthPickerSheet(
        selectedMonth: selectedMonth,
        onMonthSelected: (date) {
          onMonthChanged(date);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _ArrowButton({
    required this.icon,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          child: Icon(
            icon,
            color: enabled ? AppColors.primary : AppColors.textHint,
            size: AppSizes.iconSm,
          ),
        ),
      ),
    );
  }
}

class _MonthPickerSheet extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthSelected;

  const _MonthPickerSheet({
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentYear = now.year;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSizes.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          const Text(
            'Seleccionar Mes',
            style: TextStyle(
              fontSize: AppSizes.fontXl,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2,
                crossAxisSpacing: AppSizes.sm,
                mainAxisSpacing: AppSizes.sm,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected = selectedMonth.month == month && 
                                   selectedMonth.year == currentYear;
                final isFuture = month > now.month && currentYear >= now.year;
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isFuture 
                        ? null 
                        : () => onMonthSelected(DateTime(currentYear, month)),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.primary 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: isSelected 
                              ? AppColors.primary 
                              : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        AppStrings.months[index].substring(0, 3),
                        style: TextStyle(
                          fontSize: AppSizes.fontSm,
                          fontWeight: isSelected 
                              ? FontWeight.bold 
                              : FontWeight.w500,
                          color: isFuture 
                              ? AppColors.textHint 
                              : (isSelected 
                                  ? Colors.white 
                                  : AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}
