import 'package:flutter/material.dart';
import '../design_system/colors/app_colors_extensions.dart';
import '../design_system/spacing/app_spacing.dart';
import '../constants/responsive_constants.dart';

class OptimizedFilterBar extends StatelessWidget {
  final String? location;
  final String? category;
  final VoidCallback onRefresh;
  final VoidCallback onHome;
  final VoidCallback? onLocationTap;
  final VoidCallback? onCategoryTap;

  const OptimizedFilterBar({
    super.key,
    this.location,
    this.category,
    required this.onRefresh,
    required this.onHome,
    this.onLocationTap,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveConstants.getResponsiveSpacing(context, 'sm');
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing,
        vertical: spacing * 0.5,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(
            color: context.colors.border,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _ActionButton(
              icon: Icons.refresh,
              onPressed: onRefresh,
              tooltip: 'Refresh',
            ),
            SizedBox(width: spacing),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (location != null)
                    Flexible(
                      child: _FilterChip(
                        label: location!,
                        icon: Icons.location_on,
                        onTap: onLocationTap,
                      ),
                    ),
                  if (location != null && category != null)
                    SizedBox(width: spacing * 0.5),
                  if (category != null)
                    Flexible(
                      child: _FilterChip(
                        label: category!,
                        icon: Icons.category,
                        onTap: onCategoryTap,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: spacing),
            _ActionButton(
              icon: Icons.home,
              onPressed: onHome,
              tooltip: 'Home',
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 24,
              color: context.colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: label,
      child: Material(
        color: context.colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 36,
              minWidth: 60,
              maxWidth: 150,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: context.colors.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.colors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
