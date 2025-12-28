import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:map_awareness/services/services.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/widgets/common/premium_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();
  bool _hasKey = false, _isObscured = true, _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadKey() async {
    final key = await ApiKeyService.getGeminiKey();
    if (mounted) setState(() { _hasKey = key != null && key.isNotEmpty; if (_hasKey) _controller.text = key!; });
  }

  Future<void> _saveKey() async {
    if (_controller.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    await ApiKeyService.setGeminiKey(_controller.text.trim());
    setState(() { _isSaving = false; _hasKey = true; });
    if (mounted) ToastService.success(context, 'Saved');
  }

  Future<void> _clearKey() async {
    HapticFeedback.heavyImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 32),
              ),
              const SizedBox(height: 20),
              Text('Delete API Key?', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('This will remove your Gemini API key from the app.', style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx, false), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppTheme.error, padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Delete'))),
              ]),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    await ApiKeyService.clearGeminiKey();
    setState(() { _hasKey = false; _controller.clear(); });
    if (mounted) ToastService.error(context, 'Deleted');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
                child: Row(children: [
                  IconButton(
                    onPressed: () { HapticFeedback.selectionClick(); context.pop(); },
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.all(12)),
                  ),
                  const SizedBox(width: 12),
                  Text('Settings', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(delegate: SliverChildListDelegate([
                _buildAppInfoCard(theme),
                const SizedBox(height: 20),
                _buildApiKeyCard(theme),
                const SizedBox(height: 20),
                _buildPrivacyCard(theme),
                const SizedBox(height: 32),
              ])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(ThemeData theme) {
    return PremiumCard(
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.map_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Map Awareness', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text('v1.0.0', style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
        ])),
      ]),
    );
  }

  Widget _buildApiKeyCard(ThemeData theme) {
    return PremiumCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF651FFF)]), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Gemini API Key', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(_hasKey ? 'Configured' : 'Not configured', style: theme.textTheme.bodySmall?.copyWith(color: _hasKey ? AppTheme.success : AppTheme.error, fontWeight: FontWeight.w500)),
          ])),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _hasKey ? AppTheme.success.withValues(alpha: 0.12) : AppTheme.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Icon(_hasKey ? Icons.check_rounded : Icons.close_rounded, color: _hasKey ? AppTheme.success : AppTheme.error, size: 18),
          ),
        ]),
        const SizedBox(height: 20),

        if (!_hasKey)
          Container(
            padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.info.withValues(alpha: 0.2))),
            child: Row(children: [const Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 20), const SizedBox(width: 12), Expanded(child: Text('Get a free key at aistudio.google.com', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.info)))]),
          ),

        Container(
          decoration: BoxDecoration(color: AppTheme.surfaceContainer, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: _controller, obscureText: _isObscured, style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Enter your API key', hintStyle: TextStyle(color: AppTheme.textMuted), filled: false, border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(Icons.key_rounded, color: AppTheme.textSecondary, size: 20),
              suffixIcon: IconButton(icon: Icon(_isObscured ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: AppTheme.textSecondary, size: 20), onPressed: () => setState(() => _isObscured = !_isObscured)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveKey,
              icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save Key'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          if (_hasKey) ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _clearKey, icon: const Icon(Icons.delete_outline_rounded, size: 18), label: const Text('Delete'),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16)),
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _buildPrivacyCard(ThemeData theme) {
    return PremiumCard(
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.privacy_tip_outlined, color: AppTheme.success, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Data Privacy', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('API keys are stored locally and never sent to our servers.', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
        ])),
      ]),
    );
  }
}
