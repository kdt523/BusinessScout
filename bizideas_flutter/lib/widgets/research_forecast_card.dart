import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResearchForecastCard extends StatelessWidget {
  final Map<String, dynamic> seasonalForecast;
  final Color primaryGold;
  final Color neonPink;

  const ResearchForecastCard({
    super.key,
    required this.seasonalForecast,
    required this.primaryGold,
    required this.neonPink,
  });

  @override
  Widget build(BuildContext context) {
    if (seasonalForecast.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryGold.withOpacity(0.25), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: neonPink.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.analytics_rounded, color: neonPink, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'QUARTERLY DEMAND PROJECTIONS',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: Colors.grey[850],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ...seasonalForecast.entries.map((entry) {
            final String quarter = entry.key;
            final String description = entry.value.toString();

            // Extract percentage if available, e.g. "108%" or "95%"
            final percentMatch = RegExp(r'(\d+)%').firstMatch(description);
            final int percent = percentMatch != null ? int.parse(percentMatch.group(1)!) : 100;
            final double progress = percent / 150.0; // scale relative to 150% max

            // Assign unique colors by quarter
            Color quarterColor;
            IconData quarterIcon;
            if (quarter.contains('Q1')) {
              quarterColor = const Color(0xFF3B82F6); // Blue
              quarterIcon = Icons.ac_unit_rounded;
            } else if (quarter.contains('Q2')) {
              quarterColor = const Color(0xFFF59E0B); // Amber
              quarterIcon = Icons.wb_sunny_rounded;
            } else if (quarter.contains('Q3')) {
              quarterColor = const Color(0xFF10B981); // Emerald
              quarterIcon = Icons.filter_hdr_rounded;
            } else {
              quarterColor = const Color(0xFFEF4444); // Red
              quarterIcon = Icons.card_giftcard_rounded;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(quarterIcon, size: 14, color: quarterColor),
                          const SizedBox(width: 6),
                          Text(
                            quarter.split(' - ')[0],
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: quarterColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$percent% Cap',
                          style: GoogleFonts.outfit(
                            color: quarterColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(quarterColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          })
        ],
      ),
    );
  }
}
