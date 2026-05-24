import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tts_service.dart';

class VoiceVisualizer extends StatefulWidget {
  final double height;
  final int barCount;
  
  const VoiceVisualizer({
    super.key,
    this.height = 100.0,
    this.barCount = 30,
  });

  @override
  State<VoiceVisualizer> createState() => _VoiceVisualizerState();
}

class _VoiceVisualizerState extends State<VoiceVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _baseHeights = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Initialize random base heights for visual complexity
    for (int i = 0; i < widget.barCount; i++) {
      _baseHeights.add(0.2 + _random.nextDouble() * 0.8);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ttsService = context.watch<TtsService>();
    final isPlaying = ttsService.isPlaying;

    if (isPlaying) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              // Calculate animate multiplier
              double animValue = 1.0;
              if (isPlaying) {
                // Introduce phase shifts per bar for wave effect
                final double phase = (index / widget.barCount) * 2 * pi;
                animValue = (sin(_controller.value * 2 * pi + phase) + 1) / 2;
                // Add some random jitter
                animValue = animValue * 0.7 + 0.3 * _random.nextDouble();
              } else {
                // Gentle breathing idle state
                animValue = 0.05 + 0.02 * sin(DateTime.now().millisecondsSinceEpoch / 400.0 + index);
              }

              final double barHeight = widget.height * _baseHeights[index] * animValue;
              
              // Vibrant Royal Blue / Purple gradient color matching app_theme.dart
              final color = Color.lerp(
                const Color(0xFF2563EB), // Royal Blue
                const Color(0xFF6C63FF), // Indigo
                index / widget.barCount,
              )!;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 4.5,
                height: max(4.5, barHeight),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: isPlaying ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ] : [],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
