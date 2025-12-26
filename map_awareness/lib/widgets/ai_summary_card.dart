import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_awareness/screens/settings/settings_screen.dart';
import 'package:map_awareness/services/api_key_service.dart';
import 'package:map_awareness/utils/app_theme.dart';

/// Premium AI summary card with gradient header
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

class _AiSummaryCardState extends State<AiSummaryCard> with SingleTickerProviderStateMixin {
  bool? _hasApiKey;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _checkApiKey();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await ApiKeyService.hasGeminiKey();
    if (mounted) setState(() => _hasApiKey = hasKey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                  const Color(0xFF651FFF).withValues(alpha: 0.06),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF651FFF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5E35B1),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onRefresh != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onRefresh?.call();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: const Color(0xFF7C4DFF),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: _hasApiKey == false
                ? _buildApiKeyHint(context, theme)
                : widget.isLoading
                    ? _buildLoadingState(theme)
                    : _buildContent(theme),
          ),

          // Attribution
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Powered by Gemini',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyHint(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.error.withValues(alpha: 0.1),
            AppTheme.error.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.key_off_rounded, color: AppTheme.error, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Setup AI Summary',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'To get AI safety insights, add your free Gemini API key in settings.',
            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                HapticFeedback.selectionClick();
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                _checkApiKey();
              },
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: const Text('Open Settings'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.error,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final value = _shimmerController.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(3, (i) {
            final width = i == 0 ? 1.0 : (i == 1 ? 0.85 : 0.6);
            return Padding(
              padding: EdgeInsets.only(bottom: i < 2 ? 10 : 0),
              child: Container(
                height: 14,
                width: MediaQuery.of(context).size.width * width * 0.7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + 2 * value, 0),
                    end: Alignment(1.0 + 2 * value, 0),
                    colors: [
                      AppTheme.surfaceContainerHigh,
                      Colors.white,
                      AppTheme.surfaceContainerHigh,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (widget.summary == null || widget.summary!.isEmpty) {
      return Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: AppTheme.textMuted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tap refresh to generate safety insights...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }
    
    return Text(
      widget.summary!,
      style: theme.textTheme.bodyMedium?.copyWith(
        height: 1.6,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
