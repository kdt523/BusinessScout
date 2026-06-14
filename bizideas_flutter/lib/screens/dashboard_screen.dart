import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'band_room_screen.dart';
import 'research_report_screen.dart';
import '../widgets/responsive_web_wrapper.dart';
import '../widgets/history_report_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  final _businessController = TextEditingController(text: "Coffee Shop");
  final _cityController =
      TextEditingController(text: "New York, United States");
  bool _isLoading = false;

  List<Map<String, dynamic>> _historyReports = [];
  bool _isHistoryLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isHistoryLoading = true;
    });
    try {
      final history = await _apiService.fetchReportsHistory();
      setState(() {
        _historyReports = history;
      });
    } catch (e) {
      print("Error loading history: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isHistoryLoading = false;
        });
      }
    }
  }

  final List<String> _suggestedCities = [
    "New York, United States",
    "Tokyo, Japan",
    "Paris, France",
    "Dubai, United Arab Emirates",
  ];
  final List<String> _suggestedBusinesses = [
    "Coffee Shop",
    "Boutique Retail",
    "Co-working Space"
  ];

  Future<void> _startAnalysis() async {
    final business = _businessController.text.trim();
    final city = _cityController.text.trim();

    if (business.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final locale = ui.PlatformDispatcher.instance.locale;
      final roomId = await _apiService.createAnalysisRoom(
        business,
        city,
        userLocale: locale.toLanguageTag(),
        userCountry: locale.countryCode,
      );
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BandRoomScreen(
              roomId: roomId,
              businessType: business,
              city: city,
            ),
          ),
        );
        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to start session: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgWhite = const Color(0xFFFDFDFD);
    final primaryGold = const Color(0xFF111111);
    final neonPink = const Color(0xFFFF187F);

    return ResponsiveWebWrapper(
      child: Scaffold(
        backgroundColor: bgWhite,
        body: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              // Header
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 15 * (1.0 - value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "B SCOUT",
                      style: GoogleFonts.outfit(
                        color: neonPink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Multi-Agent Feasibility",
                      style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      "Scouting System",
                      style: GoogleFonts.outfit(
                        color: primaryGold,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Launch a collaborative team of specialized AI agents to scout locations, analyze competitor saturation, and compile a strategic business plan.",
                      style: TextStyle(
                          color: Colors.grey[700], fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Inputs Card
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1.0 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: primaryGold.withOpacity(0.35), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGold.withOpacity(0.08),
                        blurRadius: 32,
                        spreadRadius: 2,
                        offset: const Offset(0, 12),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business Type
                      const Text(
                        "What business are you opening?",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _businessController,
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: "e.g. Specialty Coffee, Coworking Hub",
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFFFAF8F5),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: primaryGold.withOpacity(0.25),
                                width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: neonPink, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Business suggestions chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _suggestedBusinesses
                            .map((b) => ActionChip(
                                  label: Text(b,
                                      style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600)),
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                      color: primaryGold.withOpacity(0.4),
                                      width: 1.0),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  onPressed: () => setState(
                                      () => _businessController.text = b),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),

                      // Target City
                      const Text(
                        "Target Location / City",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _cityController,
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: "e.g. London, United Kingdom",
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFFFAF8F5),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: primaryGold.withOpacity(0.25),
                                width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: neonPink, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // City suggestions chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _suggestedCities
                            .map((c) => ActionChip(
                                  label: Text(c,
                                      style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600)),
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                      color: primaryGold.withOpacity(0.4),
                                      width: 1.0),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  onPressed: () =>
                                      setState(() => _cityController.text = c),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 26),

                      // Trigger Button
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              neonPink,
                              neonPink.withOpacity(0.85),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: neonPink.withOpacity(0.22),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _startAnalysis,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  "Recruit Agents & Start Analysis",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3),
                                ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              _buildHistorySection(),
              const SizedBox(height: 28),

              // Workflow breakdown section
              const Text(
                "Multi-Agent Collaboration Loop",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2),
              ),
              const SizedBox(height: 12),

              // Animated Workflow items
              ...List.generate(4, (index) {
                final agents = [
                  {
                    "num": "1",
                    "name": "Orchestrator Agent",
                    "role": "Coordinator",
                    "desc":
                        "Creates the room mesh, initiates the brief, and handles participant routing.",
                    "color": neonPink
                  },
                  {
                    "num": "2",
                    "name": "Location Scout Agent",
                    "role": "Geographic Scout",
                    "desc":
                        "Evaluates foot traffic densities, calculates coordinate matrices, and updates maps.",
                    "color": primaryGold
                  },
                  {
                    "num": "3",
                    "name": "Competitor Analyst Agent",
                    "role": "Saturation Expert",
                    "desc":
                        "Gathers local competitor listings and generates comparative feasibility index scoring.",
                    "color": Colors.black
                  },
                  {
                    "num": "4",
                    "name": "Business Planner Agent",
                    "role": "Strategic Planner",
                    "desc":
                        "Models demand seasonality trends and compiles final programmatic PDF consensus report.",
                    "color": primaryGold
                  },
                ];
                final ag = agents[index];

                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 500 + (index * 150)),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 15 * (1.0 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _buildWorkflowStep(
                    number: ag["num"] as String,
                    agent: ag["name"] as String,
                    role: ag["role"] as String,
                    desc: ag["desc"] as String,
                    color: ag["color"] as Color,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ),);
  }

  Widget _buildWorkflowStep({
    required String number,
    required String agent,
    required String role,
    required String desc,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFF111111).withOpacity(0.2), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      agent,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "• $role",
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  desc,
                  style: TextStyle(
                      color: Colors.grey[700], fontSize: 10.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    final neonPink = const Color(0xFFFF187F);

    if (_isHistoryLoading && _historyReports.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF187F)),
        ),
      );
    }

    if (_historyReports.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Row(
          children: [
            const Icon(Icons.history_rounded, size: 20, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              "Recent Feasibility Reports",
              style: GoogleFonts.outfit(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFFFF187F)),
              label: Text(
                "Refresh",
                style: GoogleFonts.outfit(
                  color: neonPink,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _historyReports.length,
          itemBuilder: (context, index) {
            final item = _historyReports[index];
            final roomId = item['room_id'] as String;
            final business = item['business_type'] as String;
            final city = item['city'] as String;
            final timestampVal = item['timestamp'] as double;
            final dateStr = DateTime.fromMillisecondsSinceEpoch(
                    (timestampVal * 1000).toInt())
                .toString()
                .split('.')[0];

            return HistoryReportCard(
              roomId: roomId,
              businessType: business,
              city: city,
              dateStr: dateStr,
              apiService: _apiService,
            );
          },
        ),
      ],
    );
  }
}

