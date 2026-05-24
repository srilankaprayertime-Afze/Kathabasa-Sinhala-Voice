import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/tts_service.dart';
import '../providers/history_provider.dart';
import '../widgets/voice_visualizer.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  bool _isSettingsExpanded = false;
  
  // Categorized Preset Sinhala Phrases
  final Map<String, List<Map<String, String>>> _phrases = {
    'Greetings': [
      {'sinhala': 'ආයුබෝවන්!', 'english': 'Hello (Ayubowan)'},
      {'sinhala': 'සුභ උදෑසනක් වේවා!', 'english': 'Good Morning'},
      {'sinhala': 'සුභ සන්ධ්‍යාවක් වේවා!', 'english': 'Good Evening'},
      {'sinhala': 'ස්තූතියි!', 'english': 'Thank You'},
      {'sinhala': 'කොහොමද සැප සනීප?', 'english': 'How are you?'},
      {'sinhala': 'සුභ ගමන්!', 'english': 'Safe journey!'},
    ],
    'Travel': [
      {'sinhala': 'මට පාර කියන්න පුළුවන්ද?', 'english': 'Can you direct me?'},
      {'sinhala': 'මේක තියෙන්නේ කොහේද?', 'english': 'Where is this?'},
      {'sinhala': 'බස් නැවතුම කොහෙද තියෙන්නෙ?', 'english': 'Where is the bus stop?'},
      {'sinhala': 'මට උපකාරයක් අවශ්‍යයි.', 'english': 'I need some assistance.'},
      {'sinhala': 'කරුණාකරලා මෙතන නවත්වන්න.', 'english': 'Please stop here.'},
    ],
    'Shopping': [
      {'sinhala': 'මේකේ ගාන කීයද?', 'english': 'How much is this?'},
      {'sinhala': 'මට මේක ගන්න පුළුවන්ද?', 'english': 'Can I buy this?'},
      {'sinhala': 'මට වට්ටමක් දෙන්න පුළුවන්ද?', 'english': 'Can I have a discount?'},
      {'sinhala': 'මෙතන කාඩ් පත් ගන්නවාද?', 'english': 'Do you accept cards?'},
      {'sinhala': 'මට බිල දෙන්න.', 'english': 'Give me the bill.'},
    ],
    'Emergency': [
      {'sinhala': 'මට ඉක්මනින්ම උදව් කරන්න!', 'english': 'Help me quickly!'},
      {'sinhala': 'කරුණාකරලා දොස්තර කෙනෙක් කැඳවන්න.', 'english': 'Please call a doctor.'},
      {'sinhala': 'මගේ බඩු නැතිවෙලා.', 'english': 'I lost my belongings.'},
      {'sinhala': 'පොලීසියට කතා කරන්න!', 'english': 'Call the police!'},
      {'sinhala': 'පරෙස්සම් වෙන්න!', 'english': 'Watch out / Be careful!'},
    ]
  };

  final List<String> _voices = [
    'Algenib',
    'Achernar',
    'Achird',
    'Algieba',
    'Alnilam',
    'Aoede',
    'Autonoe',
  ];

  final Map<String, String> _voiceDescriptions = {
    'Algenib': 'Gravelly, Lower pitch',
    'Achernar': 'Soft, Higher pitch',
    'Achird': 'Friendly, Lower middle pitch',
    'Algieba': 'Smooth, Lower pitch',
    'Alnilam': 'Firm, Lower middle pitch',
    'Aoede': 'Breezy, Middle pitch',
    'Autonoe': 'Bright, Middle pitch',
  };

  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiKeyController.text = context.read<TtsService>().apiKey;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _speakText(TtsService ttsService, HistoryProvider historyProvider) async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some Sinhala text to speak!'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Unlock Safari audio context synchronously during user tap
    if (kIsWeb) ttsService.unlockAudioWeb();

    try {
      if (ttsService.mode == TtsMode.gemini) {
        await ttsService.speak(text);
        // Add to history if Gemini spoke successfully
        await historyProvider.addHistoryItem(
          text: text,
          voiceName: ttsService.voiceName,
          style: ttsService.style,
          pace: ttsService.pace,
        );
      } else {
        await ttsService.speak(text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
            action: ttsService.apiKey.isEmpty ? SnackBarAction(
              label: 'SETUP KEY',
              textColor: Colors.white,
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ) : null,
          ),
        );
      }
    }
  }

  void _downloadAudio(TtsService ttsService) async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text first!'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Preparing audio file...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      final path = await ttsService.downloadAudio(text);
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        if (path == "saved_via_share") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Use "Save to Files" or select share option to save/download.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to Downloads: ${path.split("/").last}'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  void _shareAudio(TtsService ttsService) async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text first!'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Exporting audio...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      await ttsService.shareAudio(text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ttsService = context.watch<TtsService>();
    final historyProvider = context.watch<HistoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kathabasa Sinhala Voice',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.pushNamed(context, '/history'),
            tooltip: 'History & Favorites',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mode Selection Switcher
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E24) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(28.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ttsService.setMode(TtsMode.gemini),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            decoration: BoxDecoration(
                              gradient: ttsService.mode == TtsMode.gemini
                                  ? AppTheme.primaryGradient
                                  : null,
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 18,
                                    color: ttsService.mode == TtsMode.gemini ? Colors.white : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Gemini Premium',
                                    style: TextStyle(
                                      color: ttsService.mode == TtsMode.gemini ? Colors.white : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ttsService.setMode(TtsMode.offline),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            decoration: BoxDecoration(
                              gradient: ttsService.mode == TtsMode.offline
                                  ? AppTheme.accentGradient
                                  : null,
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.portable_wifi_off_rounded,
                                    size: 18,
                                    color: ttsService.mode == TtsMode.offline ? Colors.white : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Offline TTS',
                                    style: TextStyle(
                                      color: ttsService.mode == TtsMode.offline ? Colors.white : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // API Key Warning / Manual Entry Card
              if (ttsService.mode == TtsMode.gemini && ttsService.activeApiKey.isEmpty)
                _buildApiKeyWarningCard(ttsService, isDark),

              // Sound Wave Visualizer
              const SizedBox(height: 8),
              const VoiceVisualizer(height: 80),
              const SizedBox(height: 8),

              // Steerable Config Panel (Google AI Studio Panel)
              if (ttsService.mode == TtsMode.gemini) _buildSteerableConfig(ttsService, isDark)
              else _buildOfflineConfig(ttsService, isDark),

              // Large Styled Text Input Terminal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: AppTheme.cardShadow,
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C2C35) : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Textbox Header Panel (Clear, Paste, Copy)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF24242C) : Colors.grey.shade50,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sinhala Transcript Terminal',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.grey : AppTheme.textSecondary,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.paste_rounded, size: 18),
                                  onPressed: () async {
                                    final data = await Clipboard.getData('text/plain');
                                    if (data != null && data.text != null) {
                                      _textController.text = data.text!;
                                    }
                                  },
                                  tooltip: 'Paste',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 18),
                                  onPressed: () {
                                    if (_textController.text.isNotEmpty) {
                                      Clipboard.setData(ClipboardData(text: _textController.text));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Copied to Clipboard!'), duration: Duration(seconds: 1)),
                                      );
                                    }
                                  },
                                  tooltip: 'Copy',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () => _textController.clear(),
                                  tooltip: 'Clear',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Text Field
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: _textController,
                          maxLines: 6,
                          minLines: 4,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: 'ශ්‍රී ලාංකේය සිංහල භාෂාවෙන් කියවීමට මෙහි ලියන්න...\nWrite Sinhala transcript here to speak...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Download and Export/Share Actions Deck
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    // Download WAV Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadAudio(ttsService),
                        icon: const Icon(Icons.file_download_rounded, size: 20, color: AppTheme.primaryColor),
                        label: const Text(
                          'DOWNLOAD WAV',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                            side: BorderSide(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Export / Share Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareAudio(ttsService),
                        icon: const Icon(Icons.ios_share_rounded, size: 20, color: AppTheme.accentColor),
                        label: const Text(
                          'EXPORT / SHARE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: AppTheme.accentColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                            side: BorderSide(
                              color: AppTheme.accentColor.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Actions & Speak Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    // Dynamic Speak/Stop Primary Button
                    Expanded(
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: ttsService.isPlaying 
                              ? const LinearGradient(colors: [AppTheme.errorColor, Color(0xFFF87171)])
                              : AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(30.0),
                          boxShadow: ttsService.isPlaying ? [] : AppTheme.elevatedShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: ttsService.isLoading
                              ? null
                              : () {
                                  if (ttsService.isPlaying) {
                                    ttsService.stop();
                                  } else {
                                    _speakText(ttsService, historyProvider);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          child: ttsService.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      ttsService.isPlaying ? Icons.stop_circle_rounded : Icons.record_voice_over_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      ttsService.isPlaying ? 'STOP SPEAKING' : 'SPEAK TRANSCRIPT',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tabbed Presets Library Panel
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sinhala Phrase Presets',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DefaultTabController(
                      length: _phrases.keys.length,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            dividerColor: Colors.transparent,
                            indicatorColor: AppTheme.primaryColor,
                            labelColor: AppTheme.primaryColor,
                            unselectedLabelColor: Colors.grey,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            tabs: _phrases.keys.map((cat) => Tab(text: cat)).toList(),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 240,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E24) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2C2C35) : Colors.grey.shade200,
                              ),
                            ),
                            child: TabBarView(
                              children: _phrases.keys.map((cat) {
                                final catPhrases = _phrases[cat]!;
                                return ListView.separated(
                                  padding: const EdgeInsets.all(12.0),
                                  itemCount: catPhrases.length,
                                  separatorBuilder: (_, __) => const Divider(height: 12, thickness: 0.5),
                                  itemBuilder: (context, i) {
                                    final phrase = catPhrases[i];
                                    return ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                      title: Text(
                                        phrase['sinhala']!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : AppTheme.textPrimary,
                                        ),
                                      ),
                                      subtitle: Text(
                                        phrase['english']!,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      trailing: Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.volume_up_rounded, color: AppTheme.primaryColor, size: 20),
                                          onPressed: () {
                                            _textController.text = phrase['sinhala']!;
                                            _speakText(ttsService, historyProvider);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Steerable settings UI matching Google AI Studio playground
  Widget _buildSteerableConfig(TtsService ttsService, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(color: isDark ? const Color(0xFF2C2C35) : Colors.grey.shade200),
        ),
        color: isDark ? const Color(0xFF1E1E24) : Colors.grey.shade50,
        child: ExpansionTile(
          shape: const Border(),
          initiallyExpanded: _isSettingsExpanded,
          onExpansionChanged: (expanded) => setState(() => _isSettingsExpanded = expanded),
          leading: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.settings_voice_rounded, color: AppTheme.primaryColor, size: 20),
          ),
          title: Text(
            'Steerable Studio settings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            'Voice: ${ttsService.voiceName} • Style: ${ttsService.style} • Temp: ${ttsService.temperature}',
            style: const TextStyle(fontSize: 11.5, color: Colors.grey),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 16),
                  
                  // Gemini API Key Input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gemini API Key',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey : AppTheme.textSecondary),
                      ),
                      const Text(
                        'Auto-saves as you type',
                        style: TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    onChanged: (val) async {
                      await ttsService.updateApiKey(val.trim());
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF16161C) : Colors.white,
                      isDense: true,
                      prefixIcon: const Icon(Icons.key_rounded, size: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  
                  // Audio Profile String
                  Text(
                    'Audio Profile',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey : AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    maxLines: 1,
                    onChanged: (val) => ttsService.updateGeminiConfig(audioProfile: val),
                    controller: TextEditingController(text: ttsService.audioProfile)..selection = TextSelection.fromPosition(TextPosition(offset: ttsService.audioProfile.length)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF16161C) : Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  // Director's notes block (Dropdowns)
                  Text(
                    "Director's Note",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey : AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Style Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Style', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF16161C) : Colors.white,
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(color: Colors.grey.shade400, width: 0.5),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: ttsService.style,
                                  isExpanded: true,
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppTheme.textPrimary),
                                  onChanged: (val) => ttsService.updateGeminiConfig(style: val),
                                  items: ['Vocal Smile', 'Whisper', 'Excited', 'Professional', 'Natural']
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Pace Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Pace', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF16161C) : Colors.white,
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(color: Colors.grey.shade400, width: 0.5),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: ttsService.pace,
                                  isExpanded: true,
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppTheme.textPrimary),
                                  onChanged: (val) => ttsService.updateGeminiConfig(pace: val),
                                  items: ['Natural', 'Fast', 'Slow']
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Accent Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Accent', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF16161C) : Colors.white,
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(color: Colors.grey.shade400, width: 0.5),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: ttsService.accent,
                                  isExpanded: true,
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppTheme.textPrimary),
                                  onChanged: (val) => ttsService.updateGeminiConfig(accent: val),
                                  items: ['American', 'British', 'Australian', 'Indian']
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Temperature Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Temperature',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey : AppTheme.textSecondary),
                      ),
                      Text(
                        ttsService.temperature.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  Slider(
                    value: ttsService.temperature,
                    min: 0.0,
                    max: 2.0,
                    divisions: 20,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (val) => ttsService.updateGeminiConfig(temperature: val),
                  ),

                  // Voice Selector Chips
                  Text(
                    'Prebuilt Voices',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey : AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _voices.map((v) {
                      final isSelected = ttsService.voiceName == v;
                      return ChoiceChip(
                        label: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(_voiceDescriptions[v] ?? '', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.primaryColor,
                        onSelected: (selected) {
                          if (selected) {
                            ttsService.updateGeminiConfig(voiceName: v);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Offline default sliders config
  Widget _buildOfflineConfig(TtsService ttsService, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(color: isDark ? const Color(0xFF2C2C35) : Colors.grey.shade200),
        ),
        color: isDark ? const Color(0xFF1E1E24) : Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Offline voice settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              // Speech Rate
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Speed (Speech Rate)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('${(ttsService.offlineRate * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: ttsService.offlineRate,
                min: 0.1,
                max: 1.0,
                activeColor: AppTheme.accentColor,
                onChanged: (val) => ttsService.updateOfflineConfig(rate: val),
              ),

              // Pitch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pitch', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(ttsService.offlinePitch.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: ttsService.offlinePitch,
                min: 0.5,
                max: 2.0,
                activeColor: AppTheme.accentColor,
                onChanged: (val) => ttsService.updateOfflineConfig(pitch: val),
              ),

              // Volume
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Volume', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('${(ttsService.offlineVolume * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: ttsService.offlineVolume,
                min: 0.0,
                max: 1.0,
                activeColor: AppTheme.accentColor,
                onChanged: (val) => ttsService.updateOfflineConfig(volume: val),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeyWarningCard(TtsService ttsService, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: AppTheme.errorColor, width: 1.0),
        ),
        color: AppTheme.errorColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gemini API Key Required',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your own Google AI Studio API key to use Gemini Premium. You can use Offline TTS without a key.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Enter API Key (AIzaSy...)',
                        isDense: true,
                        prefixIcon: const Icon(Icons.key_rounded, size: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final key = _apiKeyController.text.trim();
                      await ttsService.updateApiKey(key);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('API Key saved successfully!'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    ),
                    child: const Text('SAVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
