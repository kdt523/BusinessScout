import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Split path connector (Orchestrator -> Scout + Analyst)
class SplitBezierConnector extends StatefulWidget {
  final bool activeLeft;
  final bool activeRight;
  final bool doneLeft;
  final bool doneRight;
  final Color colorLeft;
  final Color colorRight;
  final Color colorParent;
  final double nodeWidth;
  final double height;
  final String label;

  const SplitBezierConnector({
    super.key,
    required this.activeLeft,
    required this.activeRight,
    required this.doneLeft,
    required this.doneRight,
    required this.colorLeft,
    required this.colorRight,
    required this.colorParent,
    required this.nodeWidth,
    this.height = 38.0,
    required this.label,
  });

  @override
  State<SplitBezierConnector> createState() => _SplitBezierConnectorState();
}

class _SplitBezierConnectorState extends State<SplitBezierConnector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasActive = widget.activeLeft || widget.activeRight;
    final color = hasActive ? const Color(0xFFFF187F) : const Color(0xFF94A3B8);
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SplitBezierPainter(
                    progress: _controller.value,
                    activeLeft: widget.activeLeft,
                    activeRight: widget.activeRight,
                    doneLeft: widget.doneLeft,
                    doneRight: widget.doneRight,
                    colorLeft: widget.colorLeft,
                    colorRight: widget.colorRight,
                    colorParent: widget.colorParent,
                    nodeWidth: widget.nodeWidth,
                  ),
                );
              },
            ),
          ),
          IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.35),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.call_split,
                    size: 9,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.label,
                    style: GoogleFonts.sourceCodePro(
                      color: color.withOpacity(0.9),
                      fontSize: 7.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitBezierPainter extends CustomPainter {
  final double progress;
  final bool activeLeft;
  final bool activeRight;
  final bool doneLeft;
  final bool doneRight;
  final Color colorLeft;
  final Color colorRight;
  final Color colorParent;
  final double nodeWidth;

  _SplitBezierPainter({
    required this.progress,
    required this.activeLeft,
    required this.activeRight,
    required this.doneLeft,
    required this.doneRight,
    required this.colorLeft,
    required this.colorRight,
    required this.colorParent,
    required this.nodeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final leftCenter = nodeWidth / 2;
    final rightCenter = w - nodeWidth / 2;
    final startOffset = Offset(w / 2, 0);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Left path
    final pathLeft = Path()
      ..moveTo(startOffset.dx, startOffset.dy)
      ..cubicTo(
        w / 2, h * 0.5,
        leftCenter, h * 0.5,
        leftCenter, h,
      );

    if (doneLeft) {
      basePaint.color = const Color(0xFF10B981);
      basePaint.strokeWidth = 2.0;
    } else if (activeLeft) {
      basePaint.color = const Color(0xFFFF187F);
      basePaint.strokeWidth = 2.0;
    } else {
      basePaint.color = const Color(0xFFE2E8F0);
      basePaint.strokeWidth = 1.0;
    }
    canvas.drawPath(pathLeft, basePaint);

    // Right path
    final pathRight = Path()
      ..moveTo(startOffset.dx, startOffset.dy)
      ..cubicTo(
        w / 2, h * 0.5,
        rightCenter, h * 0.5,
        rightCenter, h,
      );

    if (doneRight) {
      basePaint.color = const Color(0xFF10B981);
      basePaint.strokeWidth = 2.0;
    } else if (activeRight) {
      basePaint.color = const Color(0xFFFF187F);
      basePaint.strokeWidth = 2.0;
    } else {
      basePaint.color = const Color(0xFFE2E8F0);
      basePaint.strokeWidth = 1.0;
    }
    canvas.drawPath(pathRight, basePaint);

    // Pulsing photons on active paths
    if (activeLeft) {
      _drawPhoton(canvas, pathLeft, progress, const Color(0xFFFF187F));
    }
    if (activeRight) {
      _drawPhoton(canvas, pathRight, progress, const Color(0xFFFF187F));
    }
  }

  void _drawPhoton(Canvas canvas, Path path, double t, Color color) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final length = metric.length;
      final tangent = metric.getTangentForOffset(length * t);
      if (tangent != null) {
        final pos = tangent.position;

        final glowPaint = Paint()
          ..color = color.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawCircle(pos, 6.0, glowPaint);

        final corePaint = Paint()..color = Colors.white;
        canvas.drawCircle(pos, 2.5, corePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SplitBezierPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeLeft != activeLeft ||
        oldDelegate.activeRight != activeRight ||
        oldDelegate.doneLeft != doneLeft ||
        oldDelegate.doneRight != doneRight;
  }
}

// Merge path connector (Scout + Analyst -> Planner)
class MergeBezierConnector extends StatefulWidget {
  final bool activeLeft;
  final bool activeRight;
  final bool doneLeft;
  final bool doneRight;
  final bool parentActive;
  final Color colorLeft;
  final Color colorRight;
  final Color colorParent;
  final double nodeWidth;
  final double height;
  final String label;

  const MergeBezierConnector({
    super.key,
    required this.activeLeft,
    required this.activeRight,
    required this.doneLeft,
    required this.doneRight,
    required this.parentActive,
    required this.colorLeft,
    required this.colorRight,
    required this.colorParent,
    required this.nodeWidth,
    this.height = 38.0,
    required this.label,
  });

  @override
  State<MergeBezierConnector> createState() => _MergeBezierConnectorState();
}

class _MergeBezierConnectorState extends State<MergeBezierConnector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.parentActive ? widget.colorParent : const Color(0xFF94A3B8);
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _MergeBezierPainter(
                    progress: _controller.value,
                    activeLeft: widget.activeLeft,
                    activeRight: widget.activeRight,
                    doneLeft: widget.doneLeft,
                    doneRight: widget.doneRight,
                    parentActive: widget.parentActive,
                    colorLeft: widget.colorLeft,
                    colorRight: widget.colorRight,
                    colorParent: widget.colorParent,
                    nodeWidth: widget.nodeWidth,
                  ),
                );
              },
            ),
          ),
          IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.35),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.call_merge,
                    size: 9,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.label,
                    style: GoogleFonts.sourceCodePro(
                      color: color.withOpacity(0.9),
                      fontSize: 7.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MergeBezierPainter extends CustomPainter {
  final double progress;
  final bool activeLeft;
  final bool activeRight;
  final bool doneLeft;
  final bool doneRight;
  final bool parentActive;
  final Color colorLeft;
  final Color colorRight;
  final Color colorParent;
  final double nodeWidth;

  _MergeBezierPainter({
    required this.progress,
    required this.activeLeft,
    required this.activeRight,
    required this.doneLeft,
    required this.doneRight,
    required this.parentActive,
    required this.colorLeft,
    required this.colorRight,
    required this.colorParent,
    required this.nodeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final leftCenter = nodeWidth / 2;
    final rightCenter = w - nodeWidth / 2;
    final endOffset = Offset(w / 2, h);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Left input
    final pathLeft = Path()
      ..moveTo(leftCenter, 0)
      ..cubicTo(
        leftCenter, h * 0.5,
        w / 2, h * 0.5,
        endOffset.dx, endOffset.dy,
      );

    if (doneLeft) {
      basePaint.color = const Color(0xFF10B981);
      basePaint.strokeWidth = 2.0;
    } else if (parentActive) {
      basePaint.color = colorParent;
      basePaint.strokeWidth = 2.0;
    } else if (activeLeft) {
      basePaint.color = const Color(0xFFFF187F);
      basePaint.strokeWidth = 2.0;
    } else {
      basePaint.color = const Color(0xFFE2E8F0);
      basePaint.strokeWidth = 1.0;
    }
    canvas.drawPath(pathLeft, basePaint);

    // Right input
    final pathRight = Path()
      ..moveTo(rightCenter, 0)
      ..cubicTo(
        rightCenter, h * 0.5,
        w / 2, h * 0.5,
        endOffset.dx, endOffset.dy,
      );

    if (doneRight) {
      basePaint.color = const Color(0xFF10B981);
      basePaint.strokeWidth = 2.0;
    } else if (parentActive) {
      basePaint.color = colorParent;
      basePaint.strokeWidth = 2.0;
    } else if (activeRight) {
      basePaint.color = const Color(0xFFFF187F);
      basePaint.strokeWidth = 2.0;
    } else {
      basePaint.color = const Color(0xFFE2E8F0);
      basePaint.strokeWidth = 1.0;
    }
    canvas.drawPath(pathRight, basePaint);

    // Draw photons merging from both sides
    if (parentActive) {
      _drawPhoton(canvas, pathLeft, progress, colorParent);
      _drawPhoton(canvas, pathRight, progress, colorParent);
    }
  }

  void _drawPhoton(Canvas canvas, Path path, double t, Color color) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final length = metric.length;
      final tangent = metric.getTangentForOffset(length * t);
      if (tangent != null) {
        final pos = tangent.position;

        final glowPaint = Paint()
          ..color = color.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawCircle(pos, 6.0, glowPaint);

        final corePaint = Paint()..color = Colors.white;
        canvas.drawCircle(pos, 2.5, corePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MergeBezierPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeLeft != activeLeft ||
        oldDelegate.activeRight != activeRight ||
        oldDelegate.doneLeft != doneLeft ||
        oldDelegate.doneRight != doneRight ||
        oldDelegate.parentActive != parentActive;
  }
}

// Straight path connector (Planner -> Consensus)
class StraightBezierConnector extends StatefulWidget {
  final bool active;
  final bool done;
  final Color color;
  final double height;
  final String label;

  const StraightBezierConnector({
    super.key,
    required this.active,
    required this.done,
    required this.color,
    this.height = 38.0,
    required this.label,
  });

  @override
  State<StraightBezierConnector> createState() => _StraightBezierConnectorState();
}

class _StraightBezierConnectorState extends State<StraightBezierConnector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? widget.color : const Color(0xFF94A3B8);
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _StraightBezierPainter(
                    progress: _controller.value,
                    active: widget.active,
                    done: widget.done,
                    color: widget.color,
                  ),
                );
              },
            ),
          ),
          IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.35),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_downward,
                    size: 9,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.label,
                    style: GoogleFonts.sourceCodePro(
                      color: color.withOpacity(0.9),
                      fontSize: 7.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StraightBezierPainter extends CustomPainter {
  final double progress;
  final bool active;
  final bool done;
  final Color color;

  _StraightBezierPainter({
    required this.progress,
    required this.active,
    required this.done,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final startOffset = Offset(w / 2, 0);
    final endOffset = Offset(w / 2, h);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(startOffset.dx, startOffset.dy)
      ..lineTo(endOffset.dx, endOffset.dy);

    if (done) {
      basePaint.color = const Color(0xFF10B981);
      basePaint.strokeWidth = 2.0;
    } else if (active) {
      basePaint.color = color;
      basePaint.strokeWidth = 2.0;
    } else {
      basePaint.color = const Color(0xFFE2E8F0);
      basePaint.strokeWidth = 1.0;
    }
    canvas.drawPath(path, basePaint);

    if (active) {
      _drawPhoton(canvas, path, progress, color);
    }
  }

  void _drawPhoton(Canvas canvas, Path path, double t, Color color) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final length = metric.length;
      final tangent = metric.getTangentForOffset(length * t);
      if (tangent != null) {
        final pos = tangent.position;

        final glowPaint = Paint()
          ..color = color.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawCircle(pos, 6.0, glowPaint);

        final corePaint = Paint()..color = Colors.white;
        canvas.drawCircle(pos, 2.5, corePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StraightBezierPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.active != active ||
        oldDelegate.done != done;
  }
}
