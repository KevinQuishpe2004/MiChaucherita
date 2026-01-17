import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Widget de carga con shimmer para tarjetas
class ShimmerCard extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 100,
    this.width,
    this.borderRadius = AppSizes.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.surface,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Widget de carga para la lista de transacciones
class ShimmerTransactionList extends StatelessWidget {
  final int itemCount;

  const ShimmerTransactionList({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
      itemBuilder: (context, index) => const _ShimmerTransactionTile(),
    );
  }
}

class _ShimmerTransactionTile extends StatelessWidget {
  const _ShimmerTransactionTile();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 16,
              width: 60,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer para el dashboard
class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        children: [
          const ShimmerCard(height: 180),
          const SizedBox(height: AppSizes.md),
          Row(
            children: const [
              Expanded(child: ShimmerCard(height: 90)),
              SizedBox(width: AppSizes.md),
              Expanded(child: ShimmerCard(height: 90)),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          const ShimmerTransactionList(itemCount: 5),
        ],
      ),
    );
  }
}
