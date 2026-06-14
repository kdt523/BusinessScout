import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResearchMetricsDashboard extends StatelessWidget {
  final double oppScore;
  final double trafficScore;
  final double saturationScore;
  final int competitorCount;
  final Map<String, dynamic>? demographics;
  final Map<String, dynamic>? bestZoneAnchor;
  final Color primaryGold;
  final Color neonPink;

  const ResearchMetricsDashboard({
    super.key,
    required this.oppScore,
    required this.trafficScore,
    required this.saturationScore,
    required this.competitorCount,
    this.demographics,
    this.bestZoneAnchor,
    required this.primaryGold,
    required this.neonPink,
  });

  @override
  Widget build(BuildContext context) {
    // Demographics extraction
    final popLabel = demographics?['population_label'] ?? 'Unavailable';
    final popSource = demographics?['source'] ?? 'Local Presets';
    final popConfidence = demographics?['confidence'] ?? 'medium';
    final studentPop = demographics?['student_population'] ?? 'Estimated 15-20%';

    // Anchor counts extraction
    final anchorScore = (bestZoneAnchor?['anchor_score'] ?? 0.0) is double
        ? (bestZoneAnchor?['anchor_score'] ?? 0.0)
        : (bestZoneAnchor?['anchor_score'] ?? 0.0).toDouble();
    
    final anchorCounts = bestZoneAnchor?['anchor_counts'] as Map<String, dynamic>?;
    final mallsCount = anchorCounts?['malls'] ?? 0;
    final schoolsCount = (anchorCounts?['schools'] ?? 0) + (anchorCounts?['colleges_universities'] ?? 0);
    final transitCount = anchorCounts?['transit_hubs'] ?? 0;

    final cardBorderColor = primaryGold.withOpacity(0.25);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorderColor, width: 1.0),
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
                child: Icon(Icons.dashboard_customize_rounded, color: neonPink, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'FEASIBILITY INSIGHTS & METRICS',
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
          
          // 2x2 Grid of Metrics
          Column(
            children: [
              // Row 1: Foot Traffic & Market Saturation
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Foot Traffic Flow',
                      value: '${trafficScore.toStringAsFixed(1)}/10',
                      subtitle: trafficScore >= 8.0
                          ? 'High Pedestrian Flow'
                          : trafficScore >= 6.0
                              ? 'Moderate Pedestrian Flow'
                              : 'Low Pedestrian Flow',
                      icon: Icons.directions_walk_rounded,
                      color: const Color(0xFF10B981),
                      progress: trafficScore / 10.0,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Market Saturation',
                      value: '${saturationScore.toStringAsFixed(1)}/10',
                      subtitle: saturationScore >= 7.0
                          ? 'Saturated (High Risk)'
                          : saturationScore >= 4.0
                              ? 'Moderate Competition'
                              : 'Low Saturation (Favorable)',
                      icon: Icons.storefront_rounded,
                      color: saturationScore >= 7.0
                          ? const Color(0xFFEF4444)
                          : saturationScore >= 4.0
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF3B82F6),
                      progress: saturationScore / 10.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Row 2: Total Population & Demand Anchors
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildDemographicCard(
                      title: 'Total Population',
                      value: popLabel,
                      source: popSource,
                      confidence: popConfidence,
                      icon: Icons.people_outline_rounded,
                      color: const Color(0xFF8B5CF6),
                      studentPopulation: studentPop,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildAnchorCard(
                      title: 'Demand Anchors',
                      scoreValue: '${anchorScore.toStringAsFixed(1)}/10',
                      malls: mallsCount,
                      schools: schoolsCount,
                      transit: transitCount,
                      icon: Icons.hub_outlined,
                      color: const Color(0xFFEC4899),
                      progress: anchorScore / 10.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          _buildCompetitorMetric(competitorCount, primaryGold),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicCard({
    required String title,
    required String value,
    required String source,
    required String confidence,
    required IconData icon,
    required Color color,
    required String studentPopulation,
  }) {
    final isPreset = source.contains('Presets') || source.contains('Fallback');
    final sourceShort = isPreset ? 'Local Preset' : 'Live Census';
    final confidenceColor = confidence.toLowerCase() == 'high'
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(16),
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.grey[900],
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: confidenceColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  confidence.toUpperCase(),
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    color: confidenceColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sourceShort,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Student Market: $studentPopulation',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnchorCard({
    required String title,
    required String scoreValue,
    required int malls,
    required int schools,
    required int transit,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                scoreValue.split('/')[0],
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey[950],
                  height: 1.1,
                ),
              ),
              Text(
                '/10',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Malls:$malls  Schools:$schools  Transit:$transit',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.2,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorMetric(int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.storefront_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMPETITIVE LANDSCAPE',
                  style: GoogleFonts.outfit(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  count == 0 ? 'Blue Ocean Market Scenario' : '$count Active Competitors Identified',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
