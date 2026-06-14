import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const MarkdownText({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    List<Widget> children = [];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      // Check for horizontal divider
      if (trimmed == '---' || trimmed == '***') {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(
              color: const Color(0xFFECC870).withOpacity(0.3), height: 1),
        ));
        continue;
      }

      // Check for headers
      if (trimmed.startsWith('#')) {
        int level = 0;
        while (level < trimmed.length && trimmed[level] == '#') {
          level++;
        }
        final content = trimmed.substring(level).trim();
        double fontSize = 12.0;
        if (level == 1)
          fontSize = 16.0;
        else if (level == 2)
          fontSize = 14.0;
        else if (level == 3) fontSize = 12.0;

        children.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ));
        continue;
      }

      // Check for bullet lists
      bool isBullet = trimmed.startsWith('•') ||
          trimmed.startsWith('*') ||
          trimmed.startsWith('-');
      String contentLine = trimmed;
      if (isBullet) {
        contentLine = trimmed.substring(1).trim();
      }

      Widget lineWidget = Padding(
        padding: EdgeInsets.only(
          left: isBullet ? 12.0 : 0.0,
          bottom: 4.0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBullet) ...[
              const Text(
                "• ",
                style: TextStyle(
                  color: Color(0xFFFF187F),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
            Expanded(
              child: RichText(
                text: _parseInlineText(contentLine),
              ),
            ),
          ],
        ),
      );

      children.add(lineWidget);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  TextSpan _parseInlineText(String text) {
    final parts = text.split('**');
    List<TextSpan> spans = [];
    bool isBold = false;

    for (var part in parts) {
      spans.add(TextSpan(
        text: part,
        style: style?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ) ??
            TextStyle(
              color: Colors.black,
              fontSize: 11,
              height: 1.45,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
      ));
      isBold = !isBold;
    }

    return TextSpan(children: spans);
  }
}
