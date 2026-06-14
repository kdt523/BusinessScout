import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResearchRecommendationsCard extends StatelessWidget {
  final double oppScore;
  final int competitorCount;
  final Color primaryGold;
  final Color neonPink;

  const ResearchRecommendationsCard({
    super.key,
    required this.oppScore,
    required this.competitorCount,
    required this.primaryGold,
    required this.neonPink,
  });

  @override
  Widget build(BuildContext context) {
    final recommendations = <Map<String, dynamic>>[];
    
    Color accentColor;
    String statusLabel;
    
    if (oppScore >= 7.0) {
      accentColor = const Color(0xFF10B981); // Emerald Green
      statusLabel = 'Favorable Conditions';
      recommendations.add({
        'title': 'High Feasibility Execution',
        'desc': 'Strong market opportunity with highly favorable foot traffic and demographics. Excellent conditions for entry.',
        'icon': Icons.insights_rounded,
      });
      recommendations.add({
        'title': 'Premium Brand Positioning',
        'desc': 'Target affluent segments and command premium pricing to maximize margins while competition is low.',
        'icon': Icons.verified_rounded,
      });
    } else if (oppScore >= 5.0) {
      accentColor = const Color(0xFFF59E0B); // Amber
      statusLabel = 'Differentiated Approach';
      recommendations.add({
        'title': 'Differentiation Focus',
        'desc': 'Moderate market density - build unique value propositions to stand out from average competitors.',
        'icon': Icons.stars_rounded,
      });
      recommendations.add({
        'title': 'Competitor Auditing',
        'desc': 'Run targeted local audits on competitor pricing and operating hours before launching final storefront setup.',
        'icon': Icons.search_rounded,
      });
    } else {
      accentColor = const Color(0xFFEF4444); // Red
      statusLabel = 'Caution Warranted';
      recommendations.add({
        'title': 'Alternative Site Check',
        'desc': 'Challenging market conditions detected. Consider researching alternative locations or peripheral corridors.',
        'icon': Icons.warning_amber_rounded,
      });
      recommendations.add({
        'title': 'Niche Customization',
        'desc': 'If proceeding, focus on a highly specific niche market that standard mass-market competitors ignore.',
        'icon': Icons.filter_alt_rounded,
      });
    }
    
    if (competitorCount == 0) {
      recommendations.add({
        'title': 'Blue Ocean Advantage',
        'desc': 'Zero active competitors found in this immediate zone. Execute rapidly to lock in the first-mover advantage.',
        'icon': Icons.sailing_rounded,
      });
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
                  color: primaryGold.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lightbulb_outline, color: primaryGold, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'STRATEGIC RECOMMENDATIONS',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: Colors.grey[850],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: accentColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ...recommendations.asMap().entries.map((entry) {
            final idx = entry.key;
            final rec = entry.value;
            final recIcon = rec['icon'] as IconData;
            final recTitle = rec['title'] as String;
            final recDesc = rec['desc'] as String;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.06)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: accentColor, width: 4.5),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(recIcon, color: accentColor, size: 16),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${idx + 1}. $recTitle',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recDesc,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[650],
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
        ],
      ),
    );
  }
}
