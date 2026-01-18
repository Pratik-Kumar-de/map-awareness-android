import 'dart:async';
import 'package:flutter/material.dart';
import 'package:map_awareness/services/location/geocoding_service.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/utils/helpers.dart';
import 'package:map_awareness/widgets/common/premium_card.dart';

/// Builds dropdown list for autocomplete suggestions.
Widget _buildOptionsView(BuildContext context, void Function(GeocodingResult) onSelected, Iterable<GeocodingResult> options, Color accent) {
  if (options.isEmpty) return const SizedBox.shrink();
  return Align(
    alignment: Alignment.topLeft,
    child: Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200, maxWidth: 360),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: options.length,
          itemBuilder: (context, i) {
            final opt = options.elementAt(i);
            return ListTile(
              dense: true,
              leading: Icon(Icons.place_rounded, size: 20, color: accent),
              title: Text(opt.displayName, style: Theme.of(context).textTheme.bodyMedium),
              onTap: () => onSelected(opt),
            );
          },
        ),
      ),
    ),
  );
}

/// Reusable autocomplete text field for location input with debounced API suggestions.
class AutocompleteTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final Widget? suffixWidget;
  final TextInputAction textInputAction;

  const AutocompleteTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.iconColor,
    this.suffixWidget,
    this.textInputAction = TextInputAction.done,
  });

  @override
  State<AutocompleteTextField> createState() => _AutocompleteTextFieldState();
}

class _AutocompleteTextFieldState extends State<AutocompleteTextField> {
  Timer? _debounce;
  List<GeocodingResult> _suggestions = [];
  final FocusNode _focusNode = FocusNode();
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  /// Fetches suggestions with debounce, uses setState to trigger rebuild.
  void _fetchSuggestions(String query) {
    _debounce?.cancel();
    
    // Skip if query unchanged (avoids redundant calls).
    if (query == _lastQuery) return;
    _lastQuery = query;
    
    // Clear suggestions immediately for short queries.
    if (query.length < 2) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
      return;
    }
    
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await GeocodingService.search(query, limit: 5);
      // Use setState to properly trigger RawAutocomplete rebuild.
      if (mounted) setState(() => _suggestions = results);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RawAutocomplete<GeocodingResult>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      // optionsBuilder must return synchronously; async handled via setState.
      optionsBuilder: (v) {
        _fetchSuggestions(v.text);
        return _suggestions;
      },
      displayStringForOption: (result) => result.displayName,
      onSelected: (result) {
        // RawAutocomplete auto-updates controller via displayStringForOption.
        // Sync lastQuery after frame to match the updated text.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _lastQuery = widget.controller.text);
        });
        setState(() => _suggestions = []);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: theme.textTheme.bodyLarge,
          textInputAction: widget.textInputAction,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainer,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: Container(padding: const EdgeInsets.all(12), child: Icon(widget.icon, color: widget.iconColor, size: 20)),
            prefixIconConstraints: const BoxConstraints(),
            suffixIcon: widget.suffixWidget,
          ),
        );
      },
      optionsViewBuilder: (ctx, onSel, opts) => _buildOptionsView(ctx, onSel, opts, theme.colorScheme.primary),
    );
  }
}

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

  /// Builds autocomplete input field with TextInputAction based on label.
  Widget _buildInput(BuildContext context, {required TextEditingController controller, required String label, required String hint, required IconData icon, required Color iconColor, Widget? suffixWidget}) {
    final isStartField = label == 'From';
    return AutocompleteTextField(
      controller: controller,
      label: label,
      hint: hint,
      icon: icon,
      iconColor: iconColor,
      suffixWidget: suffixWidget,
      textInputAction: isStartField ? TextInputAction.next : TextInputAction.done,
    );
  }

  /// Renders the "Use my location" button with loading state support.
  Widget _buildLocationButton(BuildContext context) {
    return ActionIcon(
      icon: Icons.my_location_rounded,
      tooltip: 'Use my location',
      isLoading: isGettingLocation,
      color: Theme.of(context).colorScheme.primary,
      onTap: () {
        Haptics.light();
        onMyLocation?.call();
      },
    );
  }

  /// Renders a map selection button triggering the parent callback.
  Widget _buildMapButton(BuildContext context, VoidCallback onTap) {
    return ActionIcon(
      icon: Icons.map_outlined,
      tooltip: 'Select on map',
      color: Theme.of(context).colorScheme.secondary,
      onTap: () {
        Haptics.light();
        onTap();
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

/// Standalone location search field with focus animation, autocomplete, and integrated action buttons.
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

/// State for SearchField managing focus, autocomplete suggestions, and visual feedback.
class _SearchFieldState extends State<SearchField> {
  bool _isFocused = false;
  Timer? _debounce;
  List<GeocodingResult> _suggestions = [];
  final FocusNode _focusNode = FocusNode();
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  /// Fetches suggestions with debounce, uses setState to trigger rebuild.
  void _fetchSuggestions(String query) {
    _debounce?.cancel();
    
    // Skip if query unchanged (avoids redundant calls).
    if (query == _lastQuery) return;
    _lastQuery = query;
    
    // Clear suggestions immediately for short queries.
    if (query.length < 2) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
      return;
    }
    
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await GeocodingService.search(query, limit: 5);
      // Use setState to properly trigger RawAutocomplete rebuild.
      if (mounted) setState(() => _suggestions = results);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return RawAutocomplete<GeocodingResult>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      // optionsBuilder must return synchronously; async handled via setState.
      optionsBuilder: (v) {
        _fetchSuggestions(v.text);
        return _suggestions;
      },
      displayStringForOption: (result) => result.displayName,
      onSelected: (result) {
        // RawAutocomplete auto-updates controller via displayStringForOption.
        // Sync lastQuery after frame to match the updated text.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _lastQuery = widget.controller.text);
        });
        setState(() => _suggestions = []);
        // Triggers search after selection.
        Haptics.select();
        widget.onSearch?.call();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return AnimatedContainer(
          duration: AppTheme.animNormal,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.cardShadow(context),
            border: Border.all(color: _isFocused ? primary : Colors.transparent, width: 2),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: theme.textTheme.bodyLarge,
            textInputAction: TextInputAction.search,
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
        );
      },
      optionsViewBuilder: (ctx, onSel, opts) => _buildOptionsView(ctx, onSel, opts, primary),
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
          ActionIcon(icon: Icons.my_location_rounded, onTap: () { Haptics.light(); widget.onMyLocation?.call(); }, tooltip: 'My location'),
        if (widget.onSave != null && !widget.isSaving)
          ActionIcon(icon: Icons.bookmark_add_outlined, onTap: () { Haptics.medium(); widget.onSave?.call(); }, tooltip: 'Save location', color: theme.colorScheme.secondary),
        if (widget.isSaving)
          const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))),
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

  const ActionIcon({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.color,
    this.isLoading = false,
  });

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
