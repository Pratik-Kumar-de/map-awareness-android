import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/widgets/premium_card.dart';

/// Premium search input with modern styling
class PremiumSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onSearch;
  final VoidCallback? onMyLocation;
  final VoidCallback? onSave;
  final bool isLoading;
  final bool isSaving;
  final bool autofocus;

  const PremiumSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search location...',
    this.onSearch,
    this.onMyLocation,
    this.onSave,
    this.isLoading = false,
    this.isSaving = false,
    this.autofocus = false,
  });

  @override
  State<PremiumSearchField> createState() => _PremiumSearchFieldState();
}

class _PremiumSearchFieldState extends State<PremiumSearchField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppTheme.durationFast,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: _isFocused ? AppTheme.elevatedShadow : AppTheme.cardShadow,
        border: Border.all(
          color: _isFocused ? AppTheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: TextField(
          controller: widget.controller,
          autofocus: widget.autofocus,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: AppTheme.textMuted),
            filled: false,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
            prefixIcon: Container(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(
                Icons.search_rounded,
                color: _isFocused ? AppTheme.primary : AppTheme.textMuted,
                size: 24,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(),
            suffixIcon: _buildSuffixIcons(),
          ),
          onSubmitted: (_) {
            HapticFeedback.selectionClick();
            widget.onSearch?.call();
          },
        ),
      ),
    );
  }

  Widget _buildSuffixIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isLoading)
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          )
        else if (widget.onMyLocation != null)
          _ActionIcon(
            icon: Icons.my_location_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onMyLocation?.call();
            },
            tooltip: 'My location',
          ),
        if (widget.onSave != null && !widget.isSaving)
          _ActionIcon(
            icon: Icons.bookmark_add_outlined,
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onSave?.call();
            },
            tooltip: 'Save location',
            color: AppTheme.accent,
          ),
        if (widget.isSaving)
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;

  const _ActionIcon({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Tooltip(
          message: tooltip ?? '',
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, size: 22, color: color ?? AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// Premium location input pair for routes
class PremiumLocationInput extends StatelessWidget {
  final TextEditingController startController;
  final TextEditingController endController;
  final VoidCallback? onMyLocation;
  final VoidCallback? onSwap;
  final bool isGettingLocation;

  const PremiumLocationInput({
    super.key,
    required this.startController,
    required this.endController,
    this.onMyLocation,
    this.onSwap,
    this.isGettingLocation = false,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInput(
            context,
            controller: startController,
            label: 'From',
            hint: 'Starting point',
            icon: Icons.radio_button_on_rounded,
            iconColor: AppTheme.success,
            suffixWidget: _buildLocationButton(),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                height: 32,
                child: VerticalDivider(
                  color: AppTheme.surfaceContainerHigh,
                  thickness: 2,
                  width: 2,
                ),
              ),
              _SwapButton(onTap: onSwap),
            ],
          ),
          _buildInput(
            context,
            controller: endController,
            label: 'To',
            hint: 'Destination',
            icon: Icons.location_on_rounded,
            iconColor: AppTheme.error,
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    Widget? suffixWidget,
  }) {
    return TextField(
      controller: controller,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppTheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(),
        suffixIcon: suffixWidget,
      ),
    );
  }

  Widget _buildLocationButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isGettingLocation ? null : () {
          HapticFeedback.lightImpact();
          onMyLocation?.call();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: isGettingLocation
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location_rounded, size: 20, color: AppTheme.primary),
        ),
      ),
    );
  }
}

class _SwapButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _SwapButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: AppTheme.primary.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap?.call();
        },
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: const Icon(
            Icons.swap_vert_rounded,
            color: AppTheme.primary,
            size: 22,
          ),
        ),
      ),
    );
  }
}
