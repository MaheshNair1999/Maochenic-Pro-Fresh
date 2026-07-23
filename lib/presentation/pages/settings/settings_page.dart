// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../providers/theme_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _geminiKeyController = TextEditingController();
  bool _isLoadingKey = true;
  bool _isSavingKey = false;
  bool _hideGeminiKey = true;

  @override
  void initState() {
    super.initState();
    _loadGeminiKey();
  }

  @override
  void dispose() {
    _geminiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadGeminiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(AppConstants.geminiApiKeyPrefKey) ?? '';
    if (!mounted) return;
    setState(() {
      _geminiKeyController.text = savedKey;
      _isLoadingKey = false;
    });
  }

  Future<void> _saveGeminiKey() async {
    final key = _geminiKeyController.text.trim();
    final prefs = await SharedPreferences.getInstance();

    setState(() => _isSavingKey = true);
    try {
      if (key.isEmpty) {
        await prefs.remove(AppConstants.geminiApiKeyPrefKey);
      } else {
        await prefs.setString(AppConstants.geminiApiKeyPrefKey, key);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemini API key saved locally.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingKey = false);
      }
    }
  }

  Future<void> _clearGeminiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.geminiApiKeyPrefKey);
    if (!mounted) return;
    setState(() {
      _geminiKeyController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gemini API key removed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('Appearance'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(children: [
              RadioListTile<ThemeMode>(title: const Text('System Default'), subtitle: const Text('Follows your device setting'), secondary: const Icon(Icons.brightness_auto), value: ThemeMode.system, groupValue: themeMode, onChanged: (v) => themeNotifier.setTheme(v!)),
              const Divider(height: 1, indent: 56),
              RadioListTile<ThemeMode>(title: const Text('Light Mode'), secondary: const Icon(Icons.light_mode), value: ThemeMode.light, groupValue: themeMode, onChanged: (v) => themeNotifier.setTheme(v!)),
              const Divider(height: 1, indent: 56),
              RadioListTile<ThemeMode>(title: const Text('Dark Mode'), secondary: const Icon(Icons.dark_mode), value: ThemeMode.dark, groupValue: themeMode, onChanged: (v) => themeNotifier.setTheme(v!)),
            ]),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 24),
          const _SectionHeader('AI Configuration'),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoadingKey
                  ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator()))
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.auto_awesome, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Gemini Vision API', style: theme.textTheme.titleMedium),
                          Text('Powers AI part recognition', style: theme.textTheme.bodySmall),
                        ])),
                      ]),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _geminiKeyController,
                        obscureText: _hideGeminiKey,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: 'Gemini API Key',
                          hintText: 'Paste your Gemini API key here',
                          prefixIcon: const Icon(Icons.vpn_key_outlined),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hideGeminiKey = !_hideGeminiKey),
                            icon: Icon(_hideGeminiKey ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39C12).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF39C12).withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline, color: Color(0xFFF39C12), size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Your key stays on this device. It is stored locally and used only for Gemini requests.', style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFF39C12)))),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isSavingKey ? null : _saveGeminiKey,
                              icon: _isSavingKey
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: const Text('Save Key'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _isSavingKey ? null : _clearGeminiKey,
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ]),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

          const SizedBox(height: 24),
          const _SectionHeader('Data'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('Local Storage'),
                subtitle: const Text('All data stored on device'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF1E8449).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('SQLite', style: TextStyle(color: Color(0xFF1E8449), fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ),
              const Divider(height: 1, indent: 56),
              const ListTile(leading: Icon(Icons.wifi_off_outlined), title: Text('Offline Support'), subtitle: Text('Full functionality without internet'), trailing: Icon(Icons.check_circle, color: Color(0xFF1E8449), size: 20)),
            ]),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

          const SizedBox(height: 24),
          const _SectionHeader('About'),
          const Card(
            margin: EdgeInsets.zero,
            child: Column(children: [
              ListTile(leading: Icon(Icons.info_outline), title: Text('maochanicProFresh'), subtitle: Text('Version 1.0.0')),
              Divider(height: 1, indent: 56),
              ListTile(leading: Icon(Icons.description_outlined), title: Text('Features'), subtitle: Text('Vehicle Registration OCR • AI Part Recognition • Inventory • Job Sheets • PDF Export'), isThreeLine: true),
            ]),
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

          const SizedBox(height: 40),
          Center(child: Text('maochanicProFresh - Professional Mechanic Tools\nBuilt with Flutter & Gemini AI', style: theme.textTheme.bodySmall, textAlign: TextAlign.center)).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, letterSpacing: 1.2),
      ),
    );
  }
}
