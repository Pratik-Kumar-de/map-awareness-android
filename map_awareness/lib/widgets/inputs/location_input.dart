import 'package:flutter/material.dart';
import 'package:map_awareness/services/services.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/utils/helpers.dart';
import 'package:map_awareness/widgets/common/premium_card.dart';

/// Widget providing dual text inputs (From/To) with location services, swapping, and map callbacks.
class LocationInput extends StatelessWidget {
  final TextEditingController startController;
  final TextEditingController endController;
  final VoidCallback? onMyLocation;
  final VoidCallback? onSwap;
  final VoidCallback? onMapSelectStart;
  final VoidCallback? onMapSelectEnd;
  final bool isGettingLocation;

  const LocationInput({
    super.key,
    required this.startController,
    required this.endController,
    this.onMyLocation,
    this.onSwap,
    this.onMapSelectStart,
    this.onMapSelectEnd,
    this.isGettingLocation = false,
  });


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            iconColor: Colors.green,
            suffixWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onMapSelectStart != null) ActionIcon(icon: Icons.map_outlined, onTap: () { Haptics.light(); onMapSelectStart!(); }, tooltip: 'Select on map', color: Theme.of(context).colorScheme.secondary),
                ActionIcon(icon: Icons.my_location_rounded, onTap: isGettingLocation ? null : () { Haptics.light(); onMyLocation?.call(); }, tooltip: 'My location', isLoading: isGettingLocation),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4), 
                height: 32, 
                child: VerticalDivider(color: theme.colorScheme.outlineVariant, thickness: 2, width: 2),
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
            iconColor: theme.colorScheme.error,
            suffixWidget: onMapSelectEnd != null ? ActionIcon(icon: Icons.map_outlined, onTap: () { Haptics.light(); onMapSelectEnd!(); }, tooltip: 'Select on map', color: Theme.of(context).colorScheme.secondary) : null,
          ),
        ],
      ),
    );
  }

  /// Builds autocomplete input field with GeocodingService suggestions.
  Widget _buildInput(BuildContext context, {required TextEditingController controller, required String label, required String hint, required IconData icon, required Color iconColor, Widget? suffixWidget}) {
    final theme = Theme.of(context);
    return Autocomplete<GeocodingResult>(
      optionsBuilder: (text) => text.text.length < 2 ? [] : GeocodingService.search(text.text),
      displayStringForOption: (r) => r.displayName,
      onSelected: (r) => controller.text = r.displayName,
      fieldViewBuilder: (ctx, textController, focusNode, onSubmit) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (textController.text != controller.text) textController.text = controller.text;
        });
        controller.addListener(() {
          try {
            if (textController.text != controller.text) textController.text = controller.text;
          } catch (_) {
            // Controller may be disposed, ignore
          }
        });
        return TextField(
          controller: textController,
          focusNode: focusNode,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainer,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: Container(padding: const EdgeInsets.all(12), child: Icon(icon, color: iconColor, size: 20)),
            prefixIconConstraints: const BoxConstraints(),
            suffixIcon: suffixWidget,
          ),
        );
      },
    );
  }

}

/// Floating button to swap start and end input values.
class _SwapButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _SwapButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {
          Haptics.medium();
          onTap?.call();
        },
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(10), 
          child: Icon(Icons.swap_vert_rounded, color: theme.colorScheme.primary, size: 22),
        ),
      ),
    );
  }
}

/// Standalone location search field with focus animation and integrated action buttons (Search, My Location, Save).
class SearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onSearch;
  final VoidCallback? onMyLocation;
  final VoidCallback? onSave;
  final bool isLoading;
  final bool isSaving;

  const SearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search location...',
    this.onSearch,
    this.onMyLocation,
    this.onSave,
    this.isLoading = false,
    this.isSaving = false,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

/// State for SearchField managing focus status and visual feedback.
class _SearchFieldState extends State<SearchField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AnimatedContainer(
      duration: AppTheme.animNormal,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow(context),
        border: Border.all(color: _isFocused ? primary : Colors.transparent, width: 2),
      ),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: Autocomplete<GeocodingResult>(
          optionsBuilder: (text) => text.text.length < 2 ? [] : GeocodingService.search(text.text),
          displayStringForOption: (r) => r.displayName,
          onSelected: (r) => widget.controller.text = r.displayName,
          fieldViewBuilder: (ctx, controller, focusNode, onSubmit) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (controller.text != widget.controller.text) controller.text = widget.controller.text;
            });
            widget.controller.addListener(() {
              try {
                if (controller.text != widget.controller.text) controller.text = widget.controller.text;
              } catch (_) {
                // Controller may be disposed, ignore
              }
            });
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
                prefixIcon: Container(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(Icons.search_rounded, color: _isFocused ? primary : theme.colorScheme.onSurfaceVariant, size: 24),
                ),
                prefixIconConstraints: const BoxConstraints(),
                suffixIcon: _buildSuffixIcons(theme),
              ),
              onSubmitted: (_) {
                Haptics.select();
                widget.onSearch?.call();
              },
            );
          },
        ),
      ),
    );
  }

  /// Builds row of action icons inside the search field.
  Widget _buildSuffixIcons(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onMyLocation != null)
          ActionIcon(icon: Icons.my_location_rounded, onTap: () { Haptics.light(); widget.onMyLocation?.call(); }, tooltip: 'My location', isLoading: widget.isLoading),
        if (widget.onSave != null)
          ActionIcon(icon: Icons.bookmark_add_outlined, onTap: () { Haptics.medium(); widget.onSave?.call(); }, tooltip: 'Save location', color: theme.colorScheme.secondary, isLoading: widget.isSaving),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Reusable icon button with optional loading state and tooltip.
class ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? color;
  final bool isLoading;
  const ActionIcon({super.key, required this.icon, this.onTap, this.tooltip, this.color, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Tooltip(
          message: tooltip ?? '',
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(icon, size: 22, color: color ?? theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
