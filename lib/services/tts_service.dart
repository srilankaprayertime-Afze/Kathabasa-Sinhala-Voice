import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

enum TtsMode { gemini, offline }
enum PlaybackState { stopped, playing, paused, loading }

class TtsService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  File? _lastAudioFile;
  
  TtsMode _mode = TtsMode.gemini;
  PlaybackState _playbackState = PlaybackState.stopped;
  
  // Gemini TTS Configuration Options (Steerable parameters matching AI Studio)
  String _apiKey = '';
  final String _modelName = 'gemini-3.1-flash-tts-preview';
  String _voiceName = 'Algenib';
  String _audioProfile = 'A smooth, premium commercial voice.';
  String _scene = 'The Sound Stage Booth.';
  String _sampleContext = "Premium commercial. Dynamic pacing—starts intrigued, ends punchy. Tone is polished, persuasive, and inviting.";
  
  // Steerable Director's Notes
  String _style = 'Vocal Smile';
  String _pace = 'Natural';
  String _accent = 'American';
  double _temperature = 1.0;

  // Offline TTS Slider Settings
  double _offlinePitch = 1.0;
  double _offlineRate = 0.5;
  double _offlineVolume = 1.0;
  


  // Getters
  File? get lastAudioFile => _lastAudioFile;
  TtsMode get mode => _mode;
  PlaybackState get playbackState => _playbackState;
  bool get isPlaying => _playbackState == PlaybackState.playing;
  bool get isLoading => _playbackState == PlaybackState.loading;
  
  String get apiKey => _apiKey;
  String get modelName => _modelName;
  String get voiceName => _voiceName;
  String get audioProfile => _audioProfile;
  String get scene => _scene;
  String get sampleContext => _sampleContext;
  
  String get style => _style;
  String get pace => _pace;
  String get accent => _accent;
  double get temperature => _temperature;

  double get offlinePitch => _offlinePitch;
  double get offlineRate => _offlineRate;
  double get offlineVolume => _offlineVolume;

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    // Load config from dotenv if available
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    
    // Load saved settings from shared preferences
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('gemini_api_key') ?? _apiKey;
    _mode = TtsMode.values[prefs.getInt('tts_mode') ?? TtsMode.gemini.index];
    _voiceName = prefs.getString('gemini_voice_name') ?? 'Algenib';
    _audioProfile = prefs.getString('gemini_audio_profile') ?? 'A smooth, premium commercial voice.';
    _scene = prefs.getString('gemini_scene') ?? 'The Sound Stage Booth.';
    _sampleContext = prefs.getString('gemini_sample_context') ?? "Premium commercial. Dynamic pacing—starts intrigued, ends punchy. Tone is polished, persuasive, and inviting.";
    _style = prefs.getString('gemini_style') ?? 'Vocal Smile';
    _pace = prefs.getString('gemini_pace') ?? 'Natural';
    _accent = prefs.getString('gemini_accent') ?? 'American';
    _temperature = prefs.getDouble('gemini_temperature') ?? 1.0;

    _offlinePitch = prefs.getDouble('offline_pitch') ?? 1.0;
    _offlineRate = prefs.getDouble('offline_rate') ?? 0.5;
    _offlineVolume = prefs.getDouble('offline_volume') ?? 1.0;

    // Configure local flutter_tts
    await _flutterTts.setLanguage("si-LK");
    await _flutterTts.setPitch(_offlinePitch);
    await _flutterTts.setSpeechRate(_offlineRate);
    await _flutterTts.setVolume(_offlineVolume);

    _flutterTts.setStartHandler(() {
      _playbackState = PlaybackState.playing;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _playbackState = PlaybackState.stopped;
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      _playbackState = PlaybackState.stopped;
      notifyListeners();
    });

    // Configure audioplayers
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        _playbackState = PlaybackState.playing;
      } else if (state == PlayerState.completed || state == PlayerState.stopped) {
        _playbackState = PlaybackState.stopped;
      } else if (state == PlayerState.paused) {
        _playbackState = PlaybackState.paused;
      }
      notifyListeners();
    });

    notifyListeners();
  }

  // Setters
  Future<void> setMode(TtsMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tts_mode', mode.index);
    notifyListeners();
  }

  Future<void> updateApiKey(String key) async {
    _apiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    notifyListeners();
  }

  Future<void> updateGeminiConfig({
    String? voiceName,
    String? audioProfile,
    String? scene,
    String? sampleContext,
    String? style,
    String? pace,
    String? accent,
    double? temperature,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (voiceName != null) {
      _voiceName = voiceName;
      await prefs.setString('gemini_voice_name', voiceName);
    }
    if (audioProfile != null) {
      _audioProfile = audioProfile;
      await prefs.setString('gemini_audio_profile', audioProfile);
    }
    if (scene != null) {
      _scene = scene;
      await prefs.setString('gemini_scene', scene);
    }
    if (sampleContext != null) {
      _sampleContext = sampleContext;
      await prefs.setString('gemini_sample_context', sampleContext);
    }
    if (style != null) {
      _style = style;
      await prefs.setString('gemini_style', style);
    }
    if (pace != null) {
      _pace = pace;
      await prefs.setString('gemini_pace', pace);
    }
    if (accent != null) {
      _accent = accent;
      await prefs.setString('gemini_accent', accent);
    }
    if (temperature != null) {
      _temperature = temperature;
      await prefs.setDouble('gemini_temperature', temperature);
    }
    notifyListeners();
  }

  Future<void> updateOfflineConfig({
    double? pitch,
    double? rate,
    double? volume,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (pitch != null) {
      _offlinePitch = pitch;
      await _flutterTts.setPitch(pitch);
      await prefs.setDouble('offline_pitch', pitch);
    }
    if (rate != null) {
      _offlineRate = rate;
      await _flutterTts.setSpeechRate(rate);
      await prefs.setDouble('offline_rate', rate);
    }
    if (volume != null) {
      _offlineVolume = volume;
      await _flutterTts.setVolume(volume);
      await prefs.setDouble('offline_volume', volume);
    }
    notifyListeners();
  }

  // Core Speech Method
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    // Stop current speaking first
    await stop();

    if (_mode == TtsMode.offline) {
      _playbackState = PlaybackState.loading;
      notifyListeners();
      await _flutterTts.speak(text);
    } else {
      if (_apiKey.trim().isEmpty) {
        throw Exception("Gemini API Key is not configured. Please add it in Settings.");
      }

      _playbackState = PlaybackState.loading;
      notifyListeners();

      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=$_apiKey'
        );

        // Standardize prompt structure matching AI Studio playground
        final String directorsNote = 
            'Style: The "$_style": The soft palate is raised to keep the tone bright, sunny, and explicitly inviting. Pace: $_pace conversational pace. Accent: $_accent (Gen).';

        final prompt = '''
Read the following transcript based on the audio profile and director's note.

# Audio Profile
$_audioProfile

# Director's note
$directorsNote

## Scene:
$_scene

## Sample Context:
$_sampleContext

## Transcript:
$text
''';

        final requestBody = jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {
                  "text": prompt
                }
              ]
            }
          ],
          "generationConfig": {
            "responseModalities": ["audio"],
            "temperature": _temperature,
            "speechConfig": {
              "voiceConfig": {
                "prebuiltVoiceConfig": {
                  "voiceName": _voiceName
                }
              }
            }
          }
        });

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        );

        if (response.statusCode != 200) {
          final errorBody = jsonDecode(response.body);
          final errorMsg = errorBody['error']?['message'] ?? 'Failed to connect to Gemini API';
          throw Exception(errorMsg);
        }

        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        final candidates = responseData['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          throw Exception("No audio generated. Check your API settings or transcript content.");
        }

        final candidate = candidates[0];
        final parts = candidate['content']?['parts'] as List?;
        if (parts == null || parts.isEmpty) {
          throw Exception("Invalid content response from Gemini API.");
        }

        String? base64Audio;
        String? mimeType;

        for (var part in parts) {
          if (part['inlineData'] != null) {
            base64Audio = part['inlineData']['data'];
            mimeType = part['inlineData']['mimeType'];
            break;
          }
        }

        if (base64Audio == null) {
          throw Exception("Response did not contain inline audio data.");
        }

        // Decode raw bytes
        Uint8List rawPcm = base64.decode(base64Audio);
        
        // Convert raw PCM to a proper WAV file using standard 44-byte WAV header
        // Default Gemini TTS PCM stream configuration is 24000Hz, 1 channel (mono), 16 bits per sample
        int rate = 24000;
        if (mimeType != null && mimeType.contains('rate=')) {
          final rateMatch = RegExp(r'rate=(\d+)').firstMatch(mimeType);
          if (rateMatch != null) {
            rate = int.parse(rateMatch.group(1)!);
          }
        }

        Uint8List wavHeader = _createWavHeader(rawPcm.length, rate: rate);
        
        final Uint8List wavBytes = Uint8List(wavHeader.length + rawPcm.length);
        wavBytes.setRange(0, wavHeader.length, wavHeader);
        wavBytes.setRange(wavHeader.length, wavBytes.length, rawPcm);

        // Write to temporary directory
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/gemini_speech.wav');
        await file.writeAsBytes(wavBytes);
        _lastAudioFile = file;

        // Play audio
        _playbackState = PlaybackState.playing;
        notifyListeners();
        await _audioPlayer.play(DeviceFileSource(file.path));

      } catch (e) {
        _playbackState = PlaybackState.stopped;
        notifyListeners();
        rethrow;
      }
    }
  }

  // Playback Control Methods
  Future<void> pause() async {
    if (_mode == TtsMode.offline) {
      await _flutterTts.pause();
    } else {
      await _audioPlayer.pause();
    }
  }

  Future<void> resume() async {
    if (_mode == TtsMode.offline) {
      // flutter_tts doesn't have an explicit resume; calling speak again or letting it replay
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> stop() async {
    if (_mode == TtsMode.offline) {
      await _flutterTts.stop();
    } else {
      await _audioPlayer.stop();
    }
    _playbackState = PlaybackState.stopped;
    notifyListeners();
  }

  // Generates a proper, compliant PCM WAV 44-Byte Header in Dart
  Uint8List _createWavHeader(int dataLength, {int rate = 24000, int channels = 1, int bits = 16}) {
    final int byteRate = (rate * channels * bits) ~/ 8;
    final int blockAlign = (channels * bits) ~/ 8;
    
    final ByteData header = ByteData(44);
    
    // ChunkID "RIFF"
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    
    // ChunkSize (36 + dataLength)
    header.setUint32(4, 36 + dataLength, Endian.little);
    
    // Format "WAVE"
    header.setUint8(8, 0x57);  // W
    header.setUint8(9, 0x41);  // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    
    // Subchunk1ID "fmt "
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); //  
    
    // Subchunk1Size (16 for PCM)
    header.setUint32(16, 16, Endian.little);
    
    // AudioFormat (1 for PCM)
    header.setUint16(20, 1, Endian.little);
    
    // NumChannels
    header.setUint16(22, channels, Endian.little);
    
    // SampleRate
    header.setUint32(24, rate, Endian.little);
    
    // ByteRate
    header.setUint32(28, byteRate, Endian.little);
    
    // BlockAlign
    header.setUint16(32, blockAlign, Endian.little);
    
    // BitsPerSample
    header.setUint16(34, bits, Endian.little);
    
    // Subchunk2ID "data"
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    
    // Subchunk2Size (dataLength)
    header.setUint32(40, dataLength, Endian.little);
    
    return header.buffer.asUint8List();
  }

  Future<File?> generateOfflineAudioFile(String text) async {
    if (text.trim().isEmpty) return null;
    try {
      final tempDir = await getTemporaryDirectory();
      final String fileName = Platform.isAndroid ? "offline_speech.wav" : "offline_speech.caf";
      final filePath = "${tempDir.path}/$fileName";
      final file = File(filePath);
      
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      
      // Setup the same offline parameters
      await _flutterTts.setLanguage("si-LK");
      await _flutterTts.setPitch(_offlinePitch);
      await _flutterTts.setSpeechRate(_offlineRate);
      await _flutterTts.setVolume(_offlineVolume);
      
      // Synthesize to file (using isFullPath: true)
      final result = await _flutterTts.synthesizeToFile(text, filePath, true);
      if (result == 1 || result == true) {
        _lastAudioFile = file;
        notifyListeners();
        return file;
      }
    } catch (e) {
      debugPrint("Offline synthesize error: $e");
    }
    return null;
  }

  Future<String?> downloadAudio(String currentText) async {
    File? audioFile;
    if (_mode == TtsMode.gemini) {
      audioFile = _lastAudioFile;
    } else {
      audioFile = await generateOfflineAudioFile(currentText);
    }
    
    if (audioFile == null || !await audioFile.exists()) {
      throw Exception("No generated audio available. Please speak or generate audio first.");
    }
    
    final ext = _mode == TtsMode.gemini ? "wav" : (Platform.isAndroid ? "wav" : "caf");
    final String cleanText = currentText.length > 15 
        ? currentText.substring(0, 15).replaceAll(RegExp(r'[^\w\s\u0D80-\u0DFF]'), '') 
        : currentText.replaceAll(RegExp(r'[^\w\s\u0D80-\u0DFF]'), '');
    final String exportName = "Kathabasa_${cleanText.trim().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.$ext";
    
    if (Platform.isAndroid) {
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final targetFile = File('${downloadDir.path}/$exportName');
          await audioFile.copy(targetFile.path);
          return targetFile.path;
        }
      } catch (e) {
        debugPrint("Download direct copy failed: $e");
      }
    }
    
    // If iOS or if direct save fails on Android, fallback to system share sheets copy-to-folder
    final tempDir = await getTemporaryDirectory();
    final exportFile = File("${tempDir.path}/$exportName");
    await audioFile.copy(exportFile.path);
    
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(exportFile.path, mimeType: _mode == TtsMode.gemini ? "audio/wav" : (Platform.isAndroid ? "audio/wav" : "audio/caf"))],
        text: 'Download Kathabasa Audio',
      ),
    );
    return "saved_via_share";
  }

  Future<void> shareAudio(String currentText) async {
    File? audioFile;
    if (_mode == TtsMode.gemini) {
      audioFile = _lastAudioFile;
    } else {
      audioFile = await generateOfflineAudioFile(currentText);
    }
    
    if (audioFile == null || !await audioFile.exists()) {
      throw Exception("No generated audio available. Please speak or generate audio first.");
    }
    
    final tempDir = await getTemporaryDirectory();
    final ext = _mode == TtsMode.gemini ? "wav" : (Platform.isAndroid ? "wav" : "caf");
    final String cleanText = currentText.length > 15 
        ? currentText.substring(0, 15).replaceAll(RegExp(r'[^\w\s\u0D80-\u0DFF]'), '') 
        : currentText.replaceAll(RegExp(r'[^\w\s\u0D80-\u0DFF]'), '');
    final String exportName = "Kathabasa_${cleanText.trim().replaceAll(' ', '_')}.$ext";
    
    final exportFile = File("${tempDir.path}/$exportName");
    await audioFile.copy(exportFile.path);
    
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(exportFile.path, mimeType: _mode == TtsMode.gemini ? "audio/wav" : (Platform.isAndroid ? "audio/wav" : "audio/caf"))],
        text: 'Kathabasa Sinhala Voice Audio',
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
