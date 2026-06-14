import 'package:flutter/material.dart';

class ResponsiveWebWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color? contentBackgroundColor;
  final Color? outerBackgroundColor;

  const ResponsiveWebWrapper({
    super.key,
    required this.child,
    this.maxWidth = 900.0,
    this.contentBackgroundColor = const Color(0xFFFDFDFD),
    this.outerBackgroundColor = const Color(0xFFF1F5F9), // Sleek neutral light grey
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > maxWidth) {
      return Container(
        color: outerBackgroundColor,
        child: Center(
          child: Container(
            width: maxWidth,
            decoration: BoxDecoration(
              color: contentBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    }
    return child;
  }
}
