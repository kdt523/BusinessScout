import 'dart:async';
import 'package:flutter/material.dart';
import './markdown_text.dart';

class TypewriterPlainText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;

  const TypewriterPlainText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
  });

  @override
  State<TypewriterPlainText> createState() => _TypewriterPlainTextState();
}

class _TypewriterPlainTextState extends State<TypewriterPlainText> {
  Timer? _timer;
  int _visible = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant TypewriterPlainText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _start();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _visible = widget.text.isEmpty ? 0 : 1;
    _timer = Timer.periodic(const Duration(milliseconds: 12), (timer) {
      if (!mounted || _visible >= widget.text.length) {
        timer.cancel();
        return;
      }
      setState(() {
        _visible = (_visible + 3).clamp(0, widget.text.length);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final rawShown =
        widget.text.substring(0, _visible.clamp(0, widget.text.length));
    final shown = sanitizeUnicode(rawShown);
    final cursor = _visible < widget.text.length ? " |" : "";
    return Text(
      "$shown$cursor",
      maxLines: widget.maxLines,
      overflow: widget.maxLines == null
          ? TextOverflow.visible
          : TextOverflow.ellipsis,
      style: widget.style,
    );
  }
}

class TypewriterMarkdown extends StatefulWidget {
  final String text;

  const TypewriterMarkdown({
    super.key,
    required this.text,
  });

  @override
  State<TypewriterMarkdown> createState() => _TypewriterMarkdownState();
}

class _TypewriterMarkdownState extends State<TypewriterMarkdown> {
  Timer? _timer;
  int _visible = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant TypewriterMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _start();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _visible = widget.text.isEmpty ? 0 : 1;
    _timer = Timer.periodic(const Duration(milliseconds: 8), (timer) {
      if (!mounted || _visible >= widget.text.length) {
        timer.cancel();
        return;
      }
      setState(() {
        _visible = (_visible + 8).clamp(0, widget.text.length);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final rawShown =
        widget.text.substring(0, _visible.clamp(0, widget.text.length));
    final shown = sanitizeUnicode(rawShown);
    return MarkdownText(text: shown);
  }
}

class AnimatedMessageBubble extends StatefulWidget {
  final Widget child;
  const AnimatedMessageBubble({super.key, required this.child});

  @override
  State<AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _slide = Tween<double>(begin: 25.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Transform.translate(
            offset: Offset(0, _slide.value),
            child: ScaleTransition(
              scale: _scale,
              alignment: Alignment.bottomLeft,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

String sanitizeUnicode(String input) {
  try {
    final codeUnits = input.codeUnits;
    final cleanCodeUnits = <int>[];
    for (int i = 0; i < codeUnits.length; i++) {
      int char = codeUnits[i];
      if (char >= 0xD800 && char <= 0xDBFF) {
        if (i + 1 < codeUnits.length) {
          int next = codeUnits[i + 1];
          if (next >= 0xDC00 && next <= 0xDFFF) {
            cleanCodeUnits.add(char);
            cleanCodeUnits.add(next);
            i++;
            continue;
          }
        }
        continue;
      } else if (char >= 0xDC00 && char <= 0xDFFF) {
        continue;
      }
      cleanCodeUnits.add(char);
    }
    return String.fromCharCodes(cleanCodeUnits);
  } catch (_) {
    return input;
  }
}
