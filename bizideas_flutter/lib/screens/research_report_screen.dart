import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/research_metrics_dashboard.dart';
import '../widgets/research_competition_card.dart';
import '../widgets/research_recommendations_card.dart';
import '../widgets/research_detailed_plan_tab.dart';
import '../widgets/research_land_acquisition_card.dart';
import '../widgets/research_forecast_card.dart';
import '../widgets/mapbox_map_widget.dart';
import '../widgets/responsive_web_wrapper.dart';

class ResearchReportScreen extends StatefulWidget {
  final String roomId;
  final String businessType;
  final String city;
  final Map<String, dynamic>? reportData;

  const ResearchReportScreen({
    super.key,
    required this.roomId,
    required this.businessType,
    required this.city,
    this.reportData,
  });

  @override
  State<ResearchReportScreen> createState() => _ResearchReportScreenState();
}

class _ResearchReportScreenState extends State<ResearchReportScreen> {
  final _apiService = ApiService();
  bool _isDownloadingPdf = false;
  bool _isLoading = false;
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = widget.reportData ?? {};
    if (_data.isEmpty || !_data.containsKey('plan_details')) {
      _fetchReportData();
    }
  }

  Future<void> _fetchReportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await _apiService.getRoomMessages(widget.roomId);
      Map<String, dynamic>? foundData;

      // Locate the Business Planner's results message containing full payload
      for (final msg in messages) {
        if (msg.sender == "Business Planner" && msg.type == "data") {
          foundData = msg.data;
          break;
        }
      }

      // Fallback: search for enriched zones from Competitor Analyst if Planner message is absent
      if (foundData == null) {
        for (final msg in messages) {
          if (msg.sender == "Competitor Analyst" && msg.type == "data") {
            final enrichedZones = msg.data['enriched_zones'];
            if (enrichedZones != null && enrichedZones.isNotEmpty) {
              foundData = enrichedZones[0];
            }
            break;
          }
        }
      }

      // Final fallback: check Location Scout data
      if (foundData == null) {
        for (final msg in messages) {
          if (msg.sender == "Location Scout" && msg.type == "data") {
            final zones = msg.data['zones'];
            if (zones != null && zones.isNotEmpty) {
              foundData = zones[0];
            }
            break;
          }
        }
      }

      if (foundData != null && mounted) {
        setState(() {
          _data = foundData!;
        });
      }
    } catch (e) {
      print("[DEBUG] Error fetching report data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (kIsWeb) {
      try {
        final url = _apiService.getPdfDownloadUrl(widget.roomId);
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to download: $e', style: const TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        }
      }
      return;
    }

    setState(() {
      _isDownloadingPdf = true;
    });

    try {
      final file = await _apiService.downloadPdfReport(widget.roomId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('PDF saved to: ${file.path}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e', style: const TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryGold = const Color(0xFFECC870);
    final neonPink = const Color(0xFFFF187F);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFDFDFD),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF187F)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Reconstructing research report...',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Handle nested format if full data payload, otherwise fallback to root keys
    final bool hasFullData = _data.containsKey('best_zone');
    final Map<String, dynamic> zoneData = hasFullData 
        ? (_data['best_zone'] as Map<String, dynamic>? ?? {}) 
        : _data;

    final oppScore = (zoneData['opp_score'] ?? 0.0) is double 
        ? zoneData['opp_score'] 
        : (zoneData['opp_score'] ?? 0).toDouble();
    final trafficScore = (zoneData['traffic_score'] ?? 0.0) is double 
        ? zoneData['traffic_score'] 
        : (zoneData['traffic_score'] ?? 0).toDouble();
    final saturationScore = (zoneData['saturation_score'] ?? 0.0) is double 
        ? zoneData['saturation_score'] 
        : (zoneData['saturation_score'] ?? 0).toDouble();
    final competitorCount = zoneData['competitor_count'] ?? 0;
    final competitors = List<dynamic>.from(zoneData['competitors'] ?? []);
    final zoneName = zoneData['name'] ?? 'Primary Corridor';

    final double lat = (zoneData['lat'] ?? 0.0) is double 
        ? zoneData['lat'] 
        : (zoneData['lat'] ?? 0.0).toDouble();
    final double lng = (zoneData['lng'] ?? 0.0) is double 
        ? zoneData['lng'] 
        : (zoneData['lng'] ?? 0.0).toDouble();

    // Extracted planning fields
    final Map<String, dynamic> planDetails = hasFullData 
        ? Map<String, dynamic>.from(_data['plan_details'] ?? {}) 
        : {};
    final Map<String, dynamic> seasonalForecast = hasFullData 
        ? Map<String, dynamic>.from(_data['seasonal_forecast'] ?? {}) 
        : {};
    final List<dynamic> landResearch = hasFullData
        ? List<dynamic>.from(_data['land_research'] ?? [])
        : [];
    final Map<String, dynamic> marketProfile = hasFullData
        ? Map<String, dynamic>.from(_data['market_profile'] ?? {})
        : {};

    // Demographic and Anchor Research extraction
    final Map<String, dynamic> demographics = hasFullData
        ? Map<String, dynamic>.from(_data['demographics'] ?? {})
        : {};
    final List<dynamic> anchorResearch = hasFullData
        ? List<dynamic>.from(_data['anchor_research'] ?? [])
        : [];

    Map<String, dynamic>? bestZoneAnchor;
    if (anchorResearch.isNotEmpty) {
      for (final item in anchorResearch) {
        if (item is Map && item['zone_name'] == zoneName) {
          bestZoneAnchor = Map<String, dynamic>.from(item);
          break;
        }
      }
    }

    return ResponsiveWebWrapper(
      child: DefaultTabController(
        length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFDFD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.businessType,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                widget.city,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _isDownloadingPdf ? null : _downloadPdf,
                icon: _isDownloadingPdf
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF187F),
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: Text(
                  _isDownloadingPdf ? 'Exporting...' : 'Export PDF',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: neonPink,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: neonPink,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: neonPink,
            indicatorWeight: 2.5,
            dividerColor: primaryGold.withOpacity(0.2),
            labelStyle: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: "Overview", icon: Icon(Icons.analytics_outlined, size: 18)),
              Tab(text: "Strategic Plan", icon: Icon(Icons.article_outlined, size: 18)),
              Tab(text: "Geographic & Site", icon: Icon(Icons.location_on_outlined, size: 18)),
              Tab(text: "Market & Projections", icon: Icon(Icons.trending_up_outlined, size: 18)),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              // Tab 1: Overview
              ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildExecutiveSummaryCard(oppScore, primaryGold, neonPink),
                  const SizedBox(height: 16),
                  MapboxMapWidget(
                    lat: lat,
                    lng: lng,
                    accessToken: 'YOUR_MAPBOX_ACCESS_TOKEN',
                    locationName: zoneName,
                  ),
                  const SizedBox(height: 16),
                  ResearchMetricsDashboard(
                    oppScore: oppScore,
                    trafficScore: trafficScore,
                    saturationScore: saturationScore,
                    competitorCount: competitorCount,
                    demographics: demographics,
                    bestZoneAnchor: bestZoneAnchor,
                    primaryGold: primaryGold,
                    neonPink: neonPink,
                  ),
                  const SizedBox(height: 16),
                  ResearchRecommendationsCard(
                    oppScore: oppScore,
                    competitorCount: competitorCount,
                    primaryGold: primaryGold,
                    neonPink: neonPink,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              
              // Tab 2: Detailed Strategy Plan
              ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (planDetails.isNotEmpty)
                    ResearchDetailedPlanTab(
                      planDetails: planDetails,
                      primaryGold: primaryGold,
                      neonPink: neonPink,
                    )
                  else
                    _buildEmptyDataCard("No detailed strategy plan compiled yet. Wait for Business Planner agent to complete."),
                ],
              ),

              // Tab 3: Geographic & Site Acquisition
              ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSectionCard(
                    'Geographic Analysis',
                    Icons.map_outlined,
                    primaryGold,
                    [
                      _buildInfoRow('Recommended Corridor', zoneName, neonPink),
                      _buildInfoRow('Traffic Density Rating', '${trafficScore.toStringAsFixed(1)}/10', 
                          trafficScore >= 7.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                      _buildInfoRow('Market Density Saturation', '${saturationScore.toStringAsFixed(1)}/10',
                          saturationScore < 5.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (landResearch.isNotEmpty)
                    ResearchLandAcquisitionCard(
                      landResearch: landResearch,
                      marketProfile: marketProfile,
                      primaryGold: primaryGold,
                      neonPink: neonPink,
                    ),
                ],
              ),

              // Tab 4: Market & Projections
              ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  ResearchCompetitionCard(
                    competitorCount: competitorCount,
                    competitors: competitors,
                    primaryGold: primaryGold,
                    neonPink: neonPink,
                  ),
                  const SizedBox(height: 16),
                  if (seasonalForecast.isNotEmpty)
                    ResearchForecastCard(
                      seasonalForecast: seasonalForecast,
                      primaryGold: primaryGold,
                      neonPink: neonPink,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),);
  }

  Widget _buildExecutiveSummaryCard(double oppScore, Color primaryGold, Color neonPink) {
    final assessment = oppScore >= 7.0
        ? 'Strong Opportunity'
        : oppScore >= 5.0
            ? 'Moderate Opportunity'
            : 'Challenging Market';
    
    final assessmentColor = oppScore >= 7.0
        ? const Color(0xFF10B981)
        : oppScore >= 5.0
            ? primaryGold
            : neonPink;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            assessmentColor.withOpacity(0.06),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: assessmentColor.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: assessmentColor.withOpacity(0.04),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: assessmentColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.analytics_rounded, color: assessmentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MARKET FEASIBILITY SCORE',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey[500],
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      assessment,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    oppScore.toStringAsFixed(1),
                    style: GoogleFonts.outfit(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: assessmentColor,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/10',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: oppScore / 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(assessmentColor),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.25), width: 1.0),
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: Colors.grey[850],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDataCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.feed_outlined, size: 36, color: Colors.grey[350]),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
