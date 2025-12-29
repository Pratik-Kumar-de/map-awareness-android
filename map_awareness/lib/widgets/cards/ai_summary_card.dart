import 'package:flutter/material.dart';
import 'package:map_awareness/utils/helpers.dart';
import 'package:map_awareness/widgets/common/loading_shimmer.dart';
import 'package:map_awareness/router/app_router.dart';
import 'package:map_awareness/services/services.dart';

import 'package:map_awareness/widgets/common/glass_container.dart';

/// Widget for displaying AI-generated route summaries, handling loading and API key states.
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

/// State for AiSummaryCard managing API key verification and reactive display.
class _AiSummaryCardState extends State<AiSummaryCard> {
  bool? _hasApiKey;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  /// Verifies existence of Gemini API key in storage.
  Future<void> _checkApiKey() async {
    final hasKey = await ApiKeyService.hasGeminiKey();
    if (mounted) setState(() => _hasApiKey = hasKey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GlassContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Adaptive header.
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: primaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onRefresh != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () { Haptics.select(); widget.onRefresh?.call(); },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(padding: const EdgeInsets.all(8), child: Icon(Icons.refresh_rounded, size: 20, color: primaryColor)),
                    ),
                  ),
              ],
            ),
          ),

          // Content.
          Padding(
            padding: const EdgeInsets.all(16),
            child: _hasApiKey == false ? _buildApiKeyHint(theme) : _buildContent(theme),
          ),

          // Attribution.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome, size: 12, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text('Powered by Gemini', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Renders a prompt to configure the API key in settings if missing.
  Widget _buildApiKeyHint(ThemeData theme) {
    final errorColor = theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: errorColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.key_off_rounded, color: errorColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Setup AI Summary', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: errorColor))),
          ]),
          const SizedBox(height: 12),
          Text('To get AI safety insights, add your free Gemini API key in settings.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                Haptics.select();
                AppRouter.goToSettings();
                await Future.delayed(const Duration(milliseconds: 500));
                _checkApiKey();
              },
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: const Text('Open Settings'),
              style: FilledButton.styleFrom(backgroundColor: errorColor, padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
        ],
      ),
    );
  }

  /// Renders the summary content or loading shimmer based on state.
  Widget _buildContent(ThemeData theme) {
    if (widget.summary == null || widget.summary!.isEmpty) {
      if (widget.isLoading) {
        return LoadingShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: double.infinity, height: 14, radius: 4),
              const SizedBox(height: 10),
              ShimmerBox(width: MediaQuery.of(context).size.width * 0.7, height: 14, radius: 4),
              const SizedBox(height: 10),
              ShimmerBox(width: MediaQuery.of(context).size.width * 0.5, height: 14, radius: 4),
            ],
          ),
        );
      }
      
      return Row(children: [
        Icon(Icons.lightbulb_outline_rounded, color: theme.colorScheme.outline, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('Tap refresh to generate safety insights...', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline, fontStyle: FontStyle.italic))),
      ]);
    }

    if (widget.isLoading) {
      return LoadingShimmer(
        child: Text(widget.summary!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, color: Colors.transparent)),
      );
    }
    
    return Text(widget.summary!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, color: theme.colorScheme.onSurface));
  }
}
