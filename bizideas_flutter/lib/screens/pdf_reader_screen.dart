import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/web_iframe_stub.dart'
    if (dart.library.html) '../widgets/web_iframe_web.dart';

class PdfReaderScreen extends StatefulWidget {
  final String roomId;
  final String businessType;
  final String city;
  final Map<String, dynamic>? businessData;

  const PdfReaderScreen({
    super.key,
    required this.roomId,
    required this.businessType,
    required this.city,
    this.businessData,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final _apiService = ApiService();
  PdfController? _pdfController;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 0;
  double _zoomLevel = 1.0;
  bool _showControls = true;

  // Business metrics for charts
  Map<String, dynamic> _metrics = {};

  @override
  void initState() {
    super.initState();
    _loadPdfAndMetrics();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadPdfAndMetrics() async {
    try {
      if (kIsWeb) {
        setState(() {
          _isLoading = false;
        });
      } else {
        // Load PDF
        final file = await _apiService.downloadPdfReport(widget.roomId);
        
        setState(() {
          _pdfController = PdfController(
            document: PdfDocument.openFile(file.path),
          );
          _isLoading = false;
        });

        // Get total pages after loading
        final document = await PdfDocument.openFile(file.path);
        setState(() {
          _totalPages = document.pagesCount;
        });
      }

      // Extract metrics from business data
      if (widget.businessData != null) {
        _extractMetrics();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load report: $e";
      });
    }
  }

  void _extractMetrics() {
    // Extract business metrics for visualization
    setState(() {
      _metrics = {
        'opportunity_score': widget.businessData?['opp_score'] ?? 7.5,
        'traffic_score': widget.businessData?['traffic_score'] ?? 8.0,
        'saturation_score': widget.businessData?['saturation_score'] ?? 6.0,
        'competitor_count': widget.businessData?['competitor_count'] ?? 5,
        'competitors': widget.businessData?['competitors'] ?? [],
      };
    });
  }

  void _zoomIn() {
    if (_zoomLevel < 3.0) {
      setState(() {
        _zoomLevel += 0.25;
      });
    }
  }

  void _zoomOut() {
    if (_zoomLevel > 0.5) {
      setState(() {
        _zoomLevel -= 0.25;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _pdfController?.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pdfController?.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryGold = const Color(0xFF111111);
    final neonPink = const Color(0xFFFF187F);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${widget.businessType} Report",
              style: GoogleFonts.outfit(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.city,
              style: GoogleFonts.outfit(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download, color: neonPink),
            onPressed: () async {
              try {
                if (kIsWeb) {
                  final url = _apiService.getPdfDownloadUrl(widget.roomId);
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                } else {
                  final file = await _apiService.downloadPdfReport(widget.roomId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Report saved to ${file.path}'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to download: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              _showControls ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[700],
            ),
            onPressed: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: primaryGold.withOpacity(0.2),
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState(primaryGold)
          : _errorMessage != null
              ? _buildErrorState()
              : Column(
                  children: [
                    // Business Intelligence Dashboard
                    if (_metrics.isNotEmpty) _buildMetricsDashboard(primaryGold, neonPink),
                    
                    // PDF Viewer
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showControls = !_showControls;
                          });
                        },
                        child: Stack(
                          children: [
                            // PDF Content
                            Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: kIsWeb
                                    ? createWebPdfIframe(_apiService.getPdfDownloadUrl(widget.roomId))
                                    : PdfView(
                                        controller: _pdfController!,
                                        onPageChanged: (page) {
                                          setState(() {
                                            _currentPage = page;
                                          });
                                        },
                                        scrollDirection: Axis.vertical,
                                      ),
                              ),
                            ),

                            // Controls Overlay
                            if (_showControls) _buildControlsOverlay(primaryGold, neonPink),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLoadingState(Color primaryGold) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryGold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: primaryGold,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Loading Business Report",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Preparing your comprehensive analysis...",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            "Failed to Load Report",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? "Unknown error",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _loadPdfAndMetrics();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF187F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsDashboard(Color primaryGold, Color neonPink) {
    final oppScore = _metrics['opportunity_score'] ?? 0.0;
    final trafficScore = _metrics['traffic_score'] ?? 0.0;
    final saturationScore = _metrics['saturation_score'] ?? 0.0;
    final competitorCount = _metrics['competitor_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryGold.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: neonPink, size: 20),
              const SizedBox(width: 8),
              Text(
                "BUSINESS INTELLIGENCE",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  "Opportunity",
                  oppScore,
                  10,
                  neonPink,
                  Icons.star_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  "Traffic",
                  trafficScore,
                  10,
                  const Color(0xFF10B981),
                  Icons.directions_walk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  "Saturation",
                  saturationScore,
                  10,
                  const Color(0xFFF59E0B),
                  Icons.people_alt_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompetitorCard(
                  competitorCount,
                  primaryGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    double value,
    double maxValue,
    Color color,
    IconData icon,
  ) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
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
                  label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[700],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value.toStringAsFixed(1),
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorCard(int count, Color primaryGold) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryGold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store_outlined, size: 16, color: primaryGold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "COMPETITORS",
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[700],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: primaryGold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count == 0 ? "Blue Ocean" : "Active",
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay(Color primaryGold, Color neonPink) {
    return Positioned.fill(
      child: Column(
        children: [
          // Top Bar - Page Info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Page $_currentPage of $_totalPages",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Bottom Control Bar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom Out
                _buildControlButton(
                  Icons.zoom_out,
                  _zoomLevel <= 0.5,
                  _zoomOut,
                  Colors.grey[700]!,
                ),
                const SizedBox(width: 12),
                
                // Zoom Level
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${(_zoomLevel * 100).toInt()}%",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryGold,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Zoom In
                _buildControlButton(
                  Icons.zoom_in,
                  _zoomLevel >= 3.0,
                  _zoomIn,
                  Colors.grey[700]!,
                ),
                
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                
                // Previous Page
                _buildControlButton(
                  Icons.chevron_left,
                  _currentPage <= 1,
                  _previousPage,
                  neonPink,
                ),
                
                const SizedBox(width: 12),
                
                // Next Page
                _buildControlButton(
                  Icons.chevron_right,
                  _currentPage >= _totalPages,
                  _nextPage,
                  neonPink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    IconData icon,
    bool disabled,
    VoidCallback onPressed,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: disabled ? Colors.grey[300] : color,
            size: 24,
          ),
        ),
      ),
    );
  }
}
