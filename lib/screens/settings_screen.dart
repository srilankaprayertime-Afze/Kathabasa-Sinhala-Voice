import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/tts_service.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final ttsService = context.read<TtsService>();
    _apiKeyController.text = ttsService.apiKey;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ttsService = context.watch<TtsService>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // API Key Settings Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(color: isDark ? const Color(0xFF2C2C35) : Colors.grey.shade200),
              ),
              color: isDark ? const Color(0xFF1E1E24) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.vpn_key_rounded, color: AppTheme.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Gemini API Key',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Gemini Premium mode requires your own Google AI Studio API key. Without a saved key, the app uses Offline TTS.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: _obscureKey,
                      decoration: InputDecoration(
                        labelText: 'Enter Gemini API Key',
                        isDense: true,
                        prefixIcon: const Icon(Icons.key_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureKey = !_obscureKey),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _launchUrl('https://aistudio.google.com/'),
                            icon: const Icon(Icons.open_in_new_rounded, size: 16, color: AppTheme.primaryColor),
                            label: const Text('GET FREE API KEY', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                            style: TextButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final key = _apiKeyController.text.trim();
                            await ttsService.updateApiKey(key);
                            if (mounted) {
                              FocusScope.of(context).unfocus();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gemini API Key saved successfully!'),
                                  backgroundColor: AppTheme.successColor,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                          ),
                          child: const Text('SAVE KEY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Model Showcase Card (From User Screenshot)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(color: isDark ? const Color(0xFF2C2C35) : Colors.grey.shade200),
              ),
              color: isDark ? const Color(0xFF1E1E24) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.model_training_rounded, color: Colors.purple, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gemini 2.5 Flash TTS Preview',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            const Text(
                              'gemini-2.5-flash-preview-tts',
                              style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Powerful, low-latency speech generation model. Designed for natural outputs, steerable prompts, and new expressive audio tags for precise narration control.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.45),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBadge('Release: April 15, 2026', Colors.orange, isDark),
                        _buildBadge('Low-latency Speech', Colors.blue, isDark),
                        _buildBadge('Steerable Voices', Colors.green, isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Offline Sinhala Voice Pack Download Guide
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(color: isDark ? const Color(0xFF2C2C35) : Colors.grey.shade200),
              ),
              color: isDark ? const Color(0xFF1E1E24) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.install_mobile_rounded, color: AppTheme.accentColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sinhala Offline Voice Guide',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'For the best Offline TTS experience, make sure to download the Google Sinhala speech package on your device:',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    _buildStepRow('1', 'Open your device Settings application.'),
                    _buildStepRow('2', 'Navigate to System > Languages & input (or search "Text-to-speech output").'),
                    _buildStepRow('3', 'Ensure Preferred Engine is set to Speech Services by Google.'),
                    _buildStepRow('4', 'Tap the Settings cog next to it > Install voice data.'),
                    _buildStepRow('5', 'Search and download the "Sinhala (Sri Lanka)" package.'),
                    _buildStepRow('6', 'Restart Kathabasa App for extremely fluent local Sinhala playback!'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Theme Settings Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(color: isDark ? const Color(0xFF2C2C35) : Colors.grey.shade200),
              ),
              color: isDark ? const Color(0xFF1E1E24) : Colors.white,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                secondary: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Dark Theme Mode',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                subtitle: const Text('Toggle between light and dark backgrounds', style: TextStyle(fontSize: 11.5)),
                value: isDark,
                activeTrackColor: AppTheme.primaryColor,
                onChanged: (val) => themeProvider.toggleTheme(val),
              ),
            ),
            // About & Info / Developer Credit Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(color: isDark ? const Color(0xFF2C2C35) : Colors.grey.shade200),
              ),
              color: isDark ? const Color(0xFF1E1E24) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'About & Info',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Kathabasa Sinhala Voice',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Version 1.0.0',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(height: 20),
                    const Text(
                      'An advanced AI-powered text-to-speech studio tailored for Sri Lankan Sinhala, utilizing high-quality Gemini TTS models and local offline synthesis. Ideal for voiceovers, sharing audio, and content creation.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.45),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF16161C) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: isDark ? const Color(0xFF2C2C35) : Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.code_rounded, color: Colors.cyan, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Developer Credit',
                                style: TextStyle(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Developed by Afkar Zemer',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? color.withValues(alpha: 0.8) : color,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStepRow(String index, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              index,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
