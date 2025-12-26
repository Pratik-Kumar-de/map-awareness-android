import 'package:flutter/material.dart';
import 'package:map_awareness/services/api_key_service.dart';
import 'package:map_awareness/utils/snackbar_utils.dart';

/// Settings page for API key configuration
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _controller = TextEditingController();
  bool _hasKey = false;
  bool _isObscured = true;
  bool _isSaving = false;

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
    if (mounted) {
      setState(() {
        _hasKey = key != null && key.isNotEmpty;
        if (_hasKey) _controller.text = key!;
      });
    }
  }

  Future<void> _saveKey() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    await ApiKeyService.setGeminiKey(_controller.text.trim());
    setState(() {
      _isSaving = false;
      _hasKey = true;
    });
    if (mounted) {
      context.showSnackBar('API Key saved', color: Colors.green);
    }
  }

  Future<void> _clearKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete API Key?'),
        content: const Text('The saved Gemini API Key will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    
    await ApiKeyService.clearGeminiKey();
    setState(() {
      _hasKey = false;
      _controller.clear();
    });
    if (mounted) {
      context.showSnackBar('API Key deleted', color: Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // About Section
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.map_rounded, size: 32, color: colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Map Awareness', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Gemini API Key section
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.auto_awesome, color: colorScheme.tertiary),
                  title: const Text('Gemini API Key'),
                  subtitle: const Text('Required for AI summaries'),
                  trailing: _hasKey 
                      ? Icon(Icons.check_circle, color: colorScheme.primary)
                      : Icon(Icons.error_outline, color: colorScheme.error),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_hasKey) ...[
                        Text(
                          'Get a free key at aistudio.google.com',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _controller,
                        obscureText: _isObscured,
                        decoration: InputDecoration(
                          labelText: 'API Key',
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.key),
                          suffixIcon: IconButton(
                            icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _isObscured = !_isObscured),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isSaving ? null : _saveKey,
                              icon: _isSaving 
                                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
                                  : const Icon(Icons.save),
                              label: Text(_isSaving ? 'Saving...' : 'Save Key'),
                            ),
                          ),
                          if (_hasKey) ...[
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _clearKey,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.error,
                                side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainer,
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Data Privacy'),
              subtitle: const Text('API Keys are stored locally on your device and never transmitted to our servers.'),
            ),
          ),
        ],
      ),
    );
  }
}
