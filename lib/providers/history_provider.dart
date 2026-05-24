import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryItem {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isFavorite;
  
  // Settings used when spoken
  final String voiceName;
  final String style;
  final String pace;

  HistoryItem({
    required this.id,
    required this.text,
    required this.timestamp,
    this.isFavorite = false,
    required this.voiceName,
    required this.style,
    required this.pace,
  });

  HistoryItem copyWith({
    String? id,
    String? text,
    DateTime? timestamp,
    bool? isFavorite,
    String? voiceName,
    String? style,
    String? pace,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
      voiceName: voiceName ?? this.voiceName,
      style: style ?? this.style,
      pace: pace ?? this.pace,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isFavorite': isFavorite,
      'voiceName': voiceName,
      'style': style,
      'pace': pace,
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      isFavorite: json['isFavorite'] ?? false,
      voiceName: json['voiceName'] ?? 'Algenib',
      style: json['style'] ?? 'Vocal Smile',
      pace: json['pace'] ?? 'Natural',
    );
  }
}

class HistoryProvider extends ChangeNotifier {
  List<HistoryItem> _items = [];

  List<HistoryItem> get items => List.unmodifiable(_items);
  List<HistoryItem> get favorites => List.unmodifiable(_items.where((element) => element.isFavorite).toList());

  HistoryProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('tts_history_list');
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _items = decoded.map((e) => HistoryItem.fromJson(e)).toList();
        
        // Sort by timestamp desc (newest first)
        _items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading history: $e");
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(_items.map((e) => e.toJson()).toList());
      await prefs.setString('tts_history_list', historyJson);
    } catch (e) {
      debugPrint("Error saving history: $e");
    }
  }

  Future<void> addHistoryItem({
    required String text,
    required String voiceName,
    required String style,
    required String pace,
  }) async {
    if (text.trim().isEmpty) return;

    // Check if duplicate text exists
    final duplicateIndex = _items.indexWhere((element) => element.text.trim() == text.trim());
    if (duplicateIndex != -1) {
      // Move to top and update settings/timestamp
      final existingItem = _items.removeAt(duplicateIndex);
      _items.insert(0, existingItem.copyWith(
        timestamp: DateTime.now(),
        voiceName: voiceName,
        style: style,
        pace: pace,
      ));
    } else {
      // Add new item
      final newItem = HistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        timestamp: DateTime.now(),
        isFavorite: false,
        voiceName: voiceName,
        style: style,
        pace: pace,
      );
      _items.insert(0, newItem);
    }

    // Limit size to 50 items
    if (_items.length > 50) {
      _items = _items.sublist(0, 50);
    }

    notifyListeners();
    await _saveHistory();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _items.indexWhere((element) => element.id == id);
    if (index != -1) {
      final item = _items[index];
      _items[index] = item.copyWith(isFavorite: !item.isFavorite);
      notifyListeners();
      await _saveHistory();
    }
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((element) => element.id == id);
    notifyListeners();
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    _items.clear();
    notifyListeners();
    await _saveHistory();
  }
}
