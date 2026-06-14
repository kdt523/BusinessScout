import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/room_message.dart';
import './mapbox_map_widget.dart';
import './competitor_chart.dart';
import './markdown_text.dart';


class ScoutingResultsDashboard extends StatelessWidget {
  final List<dynamic> zones;
  final List<dynamic> events;
  final Map<String, dynamic>? mapCenter;
  final bool isScouting;
  final List<RoomMessage> messages;
  final bool isDownloadingReport;
  final VoidCallback onDownloadReport;
  final String mapboxAccessToken;

  const ScoutingResultsDashboard({
    super.key,
    required this.zones,
    required this.events,
    required this.mapCenter,
    required this.isScouting,
    required this.messages,
    required this.isDownloadingReport,
    required this.onDownloadReport,
    required this.mapboxAccessToken,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGold = Color(0xFF111111);
    const neonPink = Color(0xFFFF187F);

    if (zones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              "No geographic data gathered yet.",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Waiting for Location Scout to map the area...",
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
      );
    }

    final hasPlannerData = messages.any(
      (msg) => msg.sender == "Business Planner" && msg.type == "data",
    );
    final plannerMsg = hasPlannerData
        ? messages.firstWhere(
            (msg) => msg.sender == "Business Planner" && msg.type == "data",
          )
        : null;

    final planDetails = plannerMsg?.data['plan_details'] ?? {};
    final seasonalForecast = plannerMsg?.data['seasonal_forecast'] ?? {};

    // Safely calculate center coordinates (fallback to zones or default Naga City coordinates)
    double centerLat = 13.6218;
    double centerLng = 123.1952;
    if (mapCenter != null && mapCenter!['lat'] != null && mapCenter!['lng'] != null) {
      centerLat = (mapCenter!['lat'] as num).toDouble();
      centerLng = (mapCenter!['lng'] as num).toDouble();
    } else if (zones.isNotEmpty && zones.first['lat'] != null && zones.first['lng'] != null) {
      centerLat = (zones.first['lat'] as num).toDouble();
      centerLng = (zones.first['lng'] as num).toDouble();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. GIS 3D Mapbox Map
          MapboxMapWidget(
            lat: centerLat,
            lng: centerLng,
            accessToken: mapboxAccessToken,
            locationName: zones.isNotEmpty ? (zones.first['name'] ?? 'Best Site') : 'Best Site',
            zones: zones,
          ),
          const SizedBox(height: 16),

          // 2. Opp score charts
          if (zones.isNotEmpty && zones.first.containsKey('opp_score')) ...[
            CompetitorChart(zones: zones),
            const SizedBox(height: 16),
          ],


          // 4. Recommended Zone Analysis
          _buildRecommendedZoneCard(neonPink),
          const SizedBox(height: 16),

          // 5. Local Events & Seasonal Peaks (Scraped via Bright Data)
          _buildLocalEventsCard(primaryGold, neonPink),
          const SizedBox(height: 16),

          // 6. Strategic Business Plan
          if (hasPlannerData) ...[
            _buildStrategicPlanCard(
              planDetails,
              seasonalForecast,
              primaryGold,
              neonPink,
            ),
            const SizedBox(height: 16),
          ],

          // 7. PDF Report Download Card
          _buildPdfDownloadCard(neonPink),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRecommendedZoneCard(Color neonPink) {
    if (zones.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.0),
        ),
        child: Column(
          children: [
            Icon(Icons.location_searching, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              "No zone data available",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }

    final bestZone = zones.first;
    final String name = bestZone['name'] ?? 'Zone 1';

    double parseScore(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    final double traffic = parseScore(bestZone['traffic_score'], 0.0);
    final double saturation = parseScore(bestZone['saturation_score'], 0.0);
    final double oppScore = parseScore(bestZone['opp_score'], 0.0);
    final int competitors = bestZone['competitor_count'] ?? 0;
    final List<dynamic> compsList = List<dynamic>.from(
      bestZone['competitors'] ?? [],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPink.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: neonPink.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: neonPink,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "RECOMMENDED ZONE",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                "OPPORTUNITY INDEX",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                oppScore.toStringAsFixed(1),
                style: GoogleFonts.outfit(
                  color: neonPink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[100]),
          const SizedBox(height: 8),
          Text(
            "COMPETITOR SATURATION ANALYSIS",
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            competitors == 0
                ? "Blue ocean opportunity! There are no registered competitors in this sector."
                : "This zone contains $competitors active competitor outlet${competitors == 1 ? '' : 's'}. Foot traffic is rated at ${traffic.toStringAsFixed(1)}/10 and saturation is rated at ${saturation.toStringAsFixed(1)}/10.",
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          if (compsList.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: compsList.map((comp) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    comp.toString(),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocalEventsCard(Color primaryGold, Color neonPink) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGold.withOpacity(0.5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: primaryGold.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: Colors.black, size: 14),
              const SizedBox(width: 6),
              Text(
                "LOCAL EVENTS & SEASONAL PEAKS",
                style: GoogleFonts.outfit(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: primaryGold.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  "BRIGHT DATA SCRAPED",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 6.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "The following local calendar events shape seasonal customer flow, student presence, and tourist foot traffic surges in the area:",
            style: TextStyle(color: Colors.black54, fontSize: 10, height: 1.35),
          ),
          const SizedBox(height: 12),
          ...events.map((event) {
            final name = event['name'] ?? 'Local Event';
            final period = event['period'] ?? 'Seasonal';
            final impact = event['impact'] ?? 'Commercial spike';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFDFD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[100]!, width: 0.8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: neonPink.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.celebration_outlined,
                        color: neonPink, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111111),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                period.toString().toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          impact,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 9.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

      ),
    );
  }

  Widget _buildStrategicPlanCard(
    Map<dynamic, dynamic> planDetails,
    Map<dynamic, dynamic> seasonalForecast,
    Color primaryGold,
    Color neonPink,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGold.withOpacity(0.5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: primaryGold.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  color: Colors.black, size: 16),
              const SizedBox(width: 6),
              Text(
                "STRATEGIC FEASIBILITY PLAN",
                style: GoogleFonts.outfit(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (planDetails.containsKey('executive_summary')) ...[
            _buildPlanSection(
              title: "Executive Summary",
              content: planDetails['executive_summary'].toString(),
              accentColor: neonPink,
            ),
            const SizedBox(height: 12),
          ],
          if (planDetails.containsKey('uvp')) ...[
            _buildPlanSection(
              title: "Unique Value Proposition",
              content: planDetails['uvp'].toString(),
              accentColor: Colors.black,
            ),
            const SizedBox(height: 12),
          ],
          if (planDetails.containsKey('financials')) ...[
            _buildPlanSection(
              title: "Year 1 Financial Targets",
              content: planDetails['financials'].toString(),
              accentColor: Colors.black,
            ),
            const SizedBox(height: 12),
          ],
          if (seasonalForecast.isNotEmpty) ...[
            Text(
              "QUARTERLY DEMAND PROJECTIONS",
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            ...seasonalForecast.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("⚡ ",
                        style: TextStyle(
                          color: Color(0xFFFF187F),
                          fontSize: 10,
                        )),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "${entry.key}: ",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: entry.value.toString(),
                              style: TextStyle(
                                color: Colors.grey[850],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ]
        ],
      ),
    );
  }

  Widget _buildPlanSection({
    required String title,
    required String content,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 10,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        MarkdownText(text: content),
      ],
    );
  }

  Widget _buildPdfDownloadCard(Color neonPink) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPink.withOpacity(0.5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: neonPink.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_outlined,
              color: Color(0xFFFF187F), size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Consensual Strategy Document",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Full Report PDF compiled by Business Planner",
                  style: TextStyle(color: Colors.grey, fontSize: 9),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF187F),
                  Color(0xFFFF489F),
                ],
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: isDownloadingReport ? null : onDownloadReport,
              icon: isDownloadingReport
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_alt, size: 14, color: Colors.white),
              label: Text(
                isDownloadingReport ? "SAVING" : "SAVE",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
