import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  void _replayItem(BuildContext context, HistoryItem item, TtsService ttsService) async {
    try {
      // Temporarily update settings to match what was used when spoken
      await ttsService.updateGeminiConfig(
        voiceName: item.voiceName,
        style: item.style,
        pace: item.pace,
      );
      await ttsService.speak(item.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Replay failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final ttsService = context.watch<TtsService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History & Favorites', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            if (historyProvider.items.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.errorColor),
                tooltip: 'Clear All History',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear All History?', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text('Are you sure you want to permanently erase all spoken items and bookmarks? This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () {
                            historyProvider.clearHistory();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('All history cleared!')),
                            );
                          },
                          child: const Text('CLEAR ALL', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
          bottom: TabBar(
            dividerColor: Colors.transparent,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text('All (${historyProvider.items.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text('Starred (${historyProvider.favorites.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHistoryList(context, historyProvider.items, ttsService, isDark),
            _buildHistoryList(context, historyProvider.favorites, ttsService, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    List<HistoryItem> listItems,
    TtsService ttsService,
    bool isDark,
  ) {
    if (listItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_none_rounded,
              size: 72,
              color: isDark ? const Color(0xFF2C2C35) : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No items yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Speak transcripts from the home screen\nand they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: listItems.length,
      itemBuilder: (context, index) {
        final item = listItems[index];
        final timeString = DateFormat('MMM dd, hh:mm a').format(item.timestamp);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(
              color: isDark ? const Color(0xFF2C2C35) : Colors.grey.shade200,
            ),
          ),
          color: isDark ? const Color(0xFF1E1E24) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timestamp & configuration
                    Text(
                      timeString,
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    // Configuration chips
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        'Voice: ${item.voiceName} • ${item.style}',
                        style: const TextStyle(fontSize: 9.5, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Sinhala Spoken Text
                Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Controls row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Tap to Play/Speak
                        ElevatedButton.icon(
                          onPressed: () => _replayItem(context, item, ttsService),
                          icon: const Icon(Icons.volume_up_rounded, size: 16, color: Colors.white),
                          label: const Text('REPLAY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Load into textbox
                        OutlinedButton.icon(
                          onPressed: () {
                            // Copy to home text controller by going back or just showing a feedback
                            Navigator.pop(context);
                            // We can use a trick to pass text back if needed, or simply update a callback
                            // But since HomeScreen watches nothing directly, we can just trigger a copy
                            // Or standard behavior: copy to Clipboard and instruct them
                            // To make this super smooth, let's copy to clipboard and notify
                            // Wait, is there a better way? We can create a global event or simply copy.
                            // Let's copy to clipboard! It's very easy.
                            // Actually, let's copy to clipboard and notify them:
                            // We can also copy the text to clipboard directly!
                            // Even better, let's tell them it has been copied, and they can paste it or it is ready.
                            // Since we have a copy action, let's write a simple callback or let it copy to clipboard.
                            importToHome(context, item.text);
                          },
                          icon: const Icon(Icons.input_rounded, size: 16),
                          label: const Text('LOAD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            side: const BorderSide(color: AppTheme.primaryColor, width: 0.8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        // Toggle Favorite
                        IconButton(
                          icon: Icon(
                            item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                            color: item.isFavorite ? Colors.amber : Colors.grey,
                            size: 24,
                          ),
                          onPressed: () => context.read<HistoryProvider>().toggleFavorite(item.id),
                          tooltip: item.isFavorite ? 'Remove Favorite' : 'Add Favorite',
                        ),
                        // Delete item
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 22),
                          onPressed: () => context.read<HistoryProvider>().deleteItem(item.id),
                          tooltip: 'Delete Log',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void importToHome(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text loaded into Clipboard! Tap "PASTE" in the input terminal.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
