import 'package:flutter/material.dart';
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
                if (onMapSelectStart != null) _buildMapButton(context, onMapSelectStart!),
                _buildLocationButton(context),
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
            suffixWidget: onMapSelectEnd != null ? _buildMapButton(context, onMapSelectEnd!) : null,
          ),
        ],
      ),
    );
  }

  /// Builds a specific text input field with associated styling and suffix.
  Widget _buildInput(BuildContext context, {required TextEditingController controller, required String label, required String hint, required IconData icon, required Color iconColor, Widget? suffixWidget}) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
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
  }

  /// Renders the "Use my location" button with loading state support.
  Widget _buildLocationButton(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isGettingLocation ? null : () {
          Haptics.light();
          onMyLocation?.call();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: isGettingLocation
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.my_location_rounded, size: 20, color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  /// Renders a map selection button triggering the parent callback.
  Widget _buildMapButton(BuildContext context, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Haptics.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.map_outlined, size: 20, color: theme.colorScheme.secondary),
        ),
      ),
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
        child: TextField(
          controller: widget.controller,
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
        ),
      ),
    );
  }

  /// Builds row of action icons inside the search field.
  Widget _buildSuffixIcons(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isLoading)
          const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)))
        else if (widget.onMyLocation != null)
          _ActionIcon(icon: Icons.my_location_rounded, onTap: () { Haptics.light(); widget.onMyLocation?.call(); }, tooltip: 'My location'),
        if (widget.onSave != null && !widget.isSaving)
          _ActionIcon(icon: Icons.bookmark_add_outlined, onTap: () { Haptics.medium(); widget.onSave?.call(); }, tooltip: 'Save location', color: theme.colorScheme.secondary),
        if (widget.isSaving)
          const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Interactive icon button component for specialized search actions.
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;
  const _ActionIcon({required this.icon, required this.onTap, this.tooltip, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Tooltip(
          message: tooltip ?? '',
          child: Padding(padding: const EdgeInsets.all(12), child: Icon(icon, size: 22, color: color ?? theme.colorScheme.onSurfaceVariant)),
        ),
      ),
    );
  }
}
