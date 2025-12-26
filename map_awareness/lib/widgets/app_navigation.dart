import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_awareness/utils/app_theme.dart';

/// Custom bottom navigation with animated indicator
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.alt_route_rounded,
                label: 'Routes',
                isSelected: currentIndex == 0,
                onTap: () => _handleTap(0),
              ),
              _NavItem(
                icon: Icons.warning_amber_rounded,
                label: 'Warnings',
                isSelected: currentIndex == 1,
                onTap: () => _handleTap(1),
              ),
              _NavItem(
                icon: Icons.map_rounded,
                label: 'Map',
                isSelected: currentIndex == 2,
                onTap: () => _handleTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(int index) {
    if (index != currentIndex) {
      HapticFeedback.selectionClick();
      onTap(index);
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppTheme.durationMedium,
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: AppTheme.durationFast,
              scale: isSelected ? 1.1 : 1.0,
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
              ),
            ),
            AnimatedSize(
              duration: AppTheme.durationMedium,
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium action button with gradient
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expanded;
  final Gradient? gradient;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.expanded = true,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppTheme.durationFast,
      width: expanded ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: onPressed != null ? (gradient ?? AppTheme.primaryGradient) : null,
        color: onPressed == null ? AppTheme.surfaceContainerHigh : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () {
            HapticFeedback.mediumImpact();
            onPressed?.call();
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                else if (icon != null)
                  Icon(icon, color: Colors.white, size: 20),
                if (!isLoading && icon != null) const SizedBox(width: 10),
                if (!isLoading)
                  Text(
                    label,
                    style: TextStyle(
                      color: onPressed != null ? Colors.white : AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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

/// Secondary outline button
class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;

  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppTheme.primary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : () {
          HapticFeedback.selectionClick();
          onPressed?.call();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: onPressed != null ? buttonColor.withValues(alpha: 0.5) : AppTheme.surfaceContainerHigh,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(buttonColor),
                  ),
                )
              else if (icon != null)
                Icon(icon, color: buttonColor, size: 18),
              if (!isLoading && icon != null) const SizedBox(width: 8),
              if (!isLoading)
                Text(
                  label,
                  style: TextStyle(
                    color: onPressed != null ? buttonColor : AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip button for quick actions
class QuickChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final Color? color;

  const QuickChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primary;
    
    return Material(
      color: isSelected ? chipColor.withValues(alpha: 0.12) : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        onLongPress: () {
          HapticFeedback.heavyImpact();
          onLongPress?.call();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? chipColor : AppTheme.surfaceContainerHigh,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? chipColor : AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? chipColor : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
