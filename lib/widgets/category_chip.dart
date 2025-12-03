import 'package:flutter/material.dart';
import 'package:myapp/config/app_theme.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? selectedColor;
  final Color? unselectedColor;

  const CategoryChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMD,
          vertical: AppSizes.paddingSM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (selectedColor ?? AppColors.primary)
              : (unselectedColor ?? AppColors.surface),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: isSelected
                ? (selectedColor ?? AppColors.primary)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.textWhite : AppColors.iconGrey,
              ),
              const SizedBox(width: AppSizes.paddingXS),
            ],
            Text(
              label,
              style: AppTextStyles.subtitle2.copyWith(
                color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? imageUrl;
  final Color? color;
  final VoidCallback? onTap;
  final int? itemCount;

  const CategoryCard({
    super.key,
    required this.title,
    required this.icon,
    this.imageUrl,
    this.color,
    this.onTap,
    this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Image (if provided)
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                child: Opacity(
                  opacity: 0.3,
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: (color ?? AppColors.primary).withOpacity(0.1),
                      );
                    },
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    decoration: BoxDecoration(
                      color: (color ?? AppColors.primary).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: AppSizes.iconSizeLG,
                      color: color ?? AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingSM),

                  // Title
                  Text(
                    title,
                    style: AppTextStyles.subtitle1,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Item Count
                  if (itemCount != null) ...[
                    const SizedBox(height: AppSizes.paddingXS),
                    Text(
                      '$itemCount item',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HorizontalCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? imageUrl;
  final Color? color;
  final VoidCallback? onTap;

  const HorizontalCategoryCard({
    super.key,
    required this.title,
    required this.icon,
    this.imageUrl,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          border: Border.all(
            color: (color ?? AppColors.primary).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingSM),
              decoration: BoxDecoration(
                color: color ?? AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizes.radiusSM),
              ),
              child: Icon(
                icon,
                size: AppSizes.iconSizeMD,
                color: AppColors.textWhite,
              ),
            ),
            const SizedBox(width: AppSizes.paddingMD),

            // Title
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.subtitle1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Arrow Icon
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.iconGrey),
          ],
        ),
      ),
    );
  }
}
