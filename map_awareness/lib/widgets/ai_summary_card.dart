import 'package:flutter/material.dart';
import 'package:map_awareness/pages/settings_page.dart';
import 'package:map_awareness/services/api_key_service.dart';

/// AI summary card with loading state, refresh, and API key check
class AiSummaryCard extends StatefulWidget {
  final String? summary;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final String title;

  const AiSummaryCard({
    super.key,
    this.summary,
    this.isLoading = false,
    this.onRefresh,
    this.title = 'AI Summary',
  });

  @override
  State<AiSummaryCard> createState() => _AiSummaryCardState();
}

class _AiSummaryCardState extends State<AiSummaryCard> {
  bool? _hasApiKey;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await ApiKeyService.hasGeminiKey();
    if (mounted) setState(() => _hasApiKey = hasKey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            if (_hasApiKey == false) 
              _buildApiKeyHint(context, theme)
            else if (widget.isLoading) 
              _buildLoadingState(theme) 
            else 
              _buildContent(theme),
            const SizedBox(height: 12),
            _buildAttribution(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyHint(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.key_off, color: colorScheme.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Setup AI Summary',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'To get AI safety insights, add your free Gemini API key in settings.',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onErrorContainer),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
                _checkApiKey();
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.error,
              ),
              child: const Text('Open Settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    if (widget.title.isEmpty && widget.onRefresh == null) return const SizedBox.shrink();
    
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        if (widget.title.isNotEmpty) ...[
          Icon(Icons.auto_awesome, color: colorScheme.tertiary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title, 
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ] else if (widget.onRefresh != null) ...[
           const Spacer(),
        ],
        if (widget.onRefresh != null)
           IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: widget.onRefresh,
            tooltip: 'Regenerate',
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.tertiary,
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Column(
      children: [
        _buildSkeletonLine(theme, 1.0),
        const SizedBox(height: 8),
        _buildSkeletonLine(theme, 0.8),
        const SizedBox(height: 8),
        _buildSkeletonLine(theme, 0.6),
      ],
    );
  }

  Widget _buildSkeletonLine(ThemeData theme, double widthFactor) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (widget.summary == null || widget.summary!.isEmpty) {
      return Text(
        'Tap refresh to generate safety insights...',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    return Text(
      widget.summary!,
      style: theme.textTheme.bodyMedium?.copyWith(
        height: 1.5,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildAttribution(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Powered by Gemini',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
