import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Premium Horizontal Agent Progress Item Card
class AgentProgressItem extends StatelessWidget {
  final String agent;
  final String state;
  final Color color;
  final bool isWorking;
  final bool isDone;
  final String taskLabel;
  final IconData icon;

  const AgentProgressItem({
    super.key,
    required this.agent,
    required this.state,
    required this.color,
    required this.isWorking,
    required this.isDone,
    required this.taskLabel,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color cardBg;
    Border border;
    List<BoxShadow> shadows = [];

    if (isDone) {
      cardBg = const Color(0xFFF0FDF4);
      border = Border.all(color: const Color(0xFF10B981).withOpacity(0.55), width: 1.2);
      shadows = [
        BoxShadow(
          color: const Color(0xFF10B981).withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 3),
        )
      ];
    } else if (isWorking) {
      cardBg = color.withOpacity(0.08);
      border = Border.all(color: color.withOpacity(0.7), width: 1.4);
      shadows = [
        BoxShadow(
          color: color.withOpacity(0.12),
          blurRadius: 10,
          spreadRadius: 1,
        )
      ];
    } else {
      cardBg = Colors.white;
      border = Border.all(color: const Color(0xFFE2E8F0), width: 0.9);
      shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(0.015),
          blurRadius: 4,
          offset: const Offset(0, 1.5),
        )
      ];
    }

    return Container(
      width: 145,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: border,
        boxShadow: shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFFDCFCE7)
                      : isWorking
                          ? color.withOpacity(0.15)
                          : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFF86EFAC)
                        : isWorking
                            ? color.withOpacity(0.5)
                            : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : icon,
                  size: 12,
                  color: isDone
                      ? const Color(0xFF10B981)
                      : isWorking
                          ? color
                          : const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              if (isWorking)
                _TypingDots(color: color)
              else
                Icon(
                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isDone ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                  size: 13,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                agent,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: isDone ? const Color(0xFF166534) : Colors.black,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1.5),
              Text(
                isWorking ? taskLabel : state,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isWorking
                      ? color
                      : isDone
                          ? const Color(0xFF15803D).withOpacity(0.8)
                          : const Color(0xFF64748B),
                  fontSize: 8.0,
                  height: 1.15,
                  fontWeight: isWorking ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  final Color color;

  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
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
        return Row(
          children: List.generate(3, (index) {
            final phase = ((_controller.value + index * 0.22) % 1.0);
            final opacity = phase < 0.5 ? 0.35 + phase : 1.35 - phase;
            return Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(opacity.clamp(0.25, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
