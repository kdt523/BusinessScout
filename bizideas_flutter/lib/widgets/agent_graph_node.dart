import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Upgraded Agent Node Card - Animations removed for size and layout stability
class AgentGraphNode extends StatelessWidget {
  final String agent;
  final String title;
  final String subtitle;
  final bool active;
  final bool done;
  final double width;
  final Color color;
  final IconData icon;
  final String roleTag;

  const AgentGraphNode({
    super.key,
    required this.agent,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.done,
    required this.width,
    required this.color,
    required this.icon,
    required this.roleTag,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color;
    final isDark = themeColor == const Color(0xFF111111);
    
    Color cardBg;
    Border border;
    List<BoxShadow> shadows = [];
    
    if (done) {
      cardBg = const Color(0xFFF0FDF4); // Very soft green
      border = Border.all(color: const Color(0xFF10B981).withOpacity(0.55), width: 1.2);
      shadows = [
        BoxShadow(
          color: const Color(0xFF10B981).withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 3),
        )
      ];
    } else if (active) {
      cardBg = themeColor.withOpacity(0.06);
      border = Border.all(color: themeColor.withOpacity(0.75), width: 1.5);
      shadows = [
        BoxShadow(
          color: themeColor.withOpacity(0.12),
          blurRadius: 6,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 4,
          offset: const Offset(0, 2),
        )
      ];
    } else {
      cardBg = Colors.white;
      border = Border.all(color: const Color(0xFFE2E8F0), width: 1.0);
      shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(0.015),
          blurRadius: 6,
          offset: const Offset(0, 2),
        )
      ];
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: border,
        boxShadow: shadows,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? const Color(0xFFDCFCE7)
                  : active
                      ? themeColor.withOpacity(0.12)
                      : const Color(0xFFF1F5F9),
              border: Border.all(
                color: done
                    ? const Color(0xFF86EFAC)
                    : active
                        ? themeColor.withOpacity(0.3)
                        : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: Icon(
              done ? Icons.check_circle_rounded : icon,
              color: done
                  ? const Color(0xFF10B981)
                  : active
                      ? themeColor
                      : const Color(0xFF64748B),
              size: done ? 18 : 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: done ? const Color(0xFF166534) : Colors.black,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: done
                            ? const Color(0xFFDCFCE7)
                            : active
                                ? themeColor.withOpacity(0.15)
                                : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        roleTag,
                        style: GoogleFonts.outfit(
                          color: done
                              ? const Color(0xFF15803D)
                              : active
                                  ? (isDark ? Colors.grey[850] : themeColor)
                                  : const Color(0xFF64748B),
                          fontSize: 6.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active
                        ? themeColor.withOpacity(0.9)
                        : done
                            ? const Color(0xFF15803D).withOpacity(0.8)
                            : const Color(0xFF64748B),
                    fontSize: 8.2,
                    height: 1.2,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Blinking cursor
class BlinkingCursor extends StatefulWidget {
  final Color color;
  const BlinkingCursor({super.key, required this.color});

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
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
          opacity: _controller.value > 0.5 ? 1.0 : 0.0,
          child: Text(
            "█",
            style: TextStyle(
              color: widget.color,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
