import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

  class FallingEmojis extends StatefulWidget {
    final int count;
    final bool enabled;

    const FallingEmojis({super.key, this.count = 30, this.enabled = false});

    @override
    State<FallingEmojis> createState() => _FallingEmojisState();
  }

  class _FallingEmojisState extends State<FallingEmojis>
      with SingleTickerProviderStateMixin {
    late final Ticker _ticker;
    late final List<_Emoji> _emojis;
    final List<String> _emojiList = [
      '✨', '💡', '🚀', '🎯', '🌟', '🔥', '🌙', '🌞', '🛸',
      '⚡', '🌈', '🧠', '💫', '🎉', '🎶', '🎨', '💥', '🌊',
      '🌪️', '🌺', '🍀', '🕹️', '📡', '🧩', '📚', '🎁'
    ];

    @override
    void initState() {
      super.initState();
      final Random rand = Random();
      _emojis = List.generate(widget.count, (index) {
        return _Emoji(
          emoji: _emojiList[rand.nextInt(_emojiList.length)],
          x: rand.nextDouble(),
          y: rand.nextDouble(),
          size: rand.nextDouble() * 16 + 16,
          speed: rand.nextDouble() * 0.01 + 0.005, 
        );
      });

      _ticker = createTicker((_) {
        if (!widget.enabled) return;

        setState(() {
          for (var e in _emojis) {
            e.y += e.speed;
            if (e.y > 1) {
              e.y = 0;
              e.x = rand.nextDouble();
            }
          }
        });
      });

      if (widget.enabled) _ticker.start();
    }

    @override
    void didUpdateWidget(covariant FallingEmojis oldWidget) {
      super.didUpdateWidget(oldWidget);
      if (widget.enabled && !_ticker.isActive) {
        _ticker.start();
      } else if (!widget.enabled && _ticker.isActive) {
        _ticker.stop();
      }
    }

    @override
    void dispose() {
      _ticker.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      if (!widget.enabled) return const SizedBox.shrink();

      final width = MediaQuery.of(context).size.width;
      final height = MediaQuery.of(context).size.height;

      return Stack(
        children: _emojis.map((e) {
          return Positioned(
            left: e.x * width,
            top: e.y * height,
            child: Text(
              e.emoji,
              style: TextStyle(
                fontSize: e.size,
                decoration: TextDecoration.none,
              ),
            ),
          );
        }).toList(),
      );
    }
  }

  class _Emoji {
    String emoji;
    double x;
    double y;
    double size;
    double speed;
    _Emoji({
      required this.emoji,
      required this.x,
      required this.y,
      required this.size,
      required this.speed,
    });
  }

