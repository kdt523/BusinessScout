import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/room_message.dart';
import '../services/api_service.dart';
import '../widgets/bezier_connectors.dart';
import '../widgets/agent_graph_node.dart';
import '../widgets/agent_progress_item.dart';
import '../widgets/scouting_results_dashboard.dart';
import '../widgets/collaboration_chatbox.dart';
import './research_report_screen.dart';
import '../widgets/responsive_web_wrapper.dart';
import '../widgets/band_orchestration_graph.dart';

class BandRoomScreen extends StatefulWidget {
  final String roomId;
  final String businessType;
  final String city;

  const BandRoomScreen({
    super.key,
    required this.roomId,
    required this.businessType,
    required this.city,
  });

  @override
  State<BandRoomScreen> createState() => _BandRoomScreenState();
}

class _BandRoomScreenState extends State<BandRoomScreen> {
  final _apiService = ApiService();
  final List<RoomMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<RoomMessage>? _streamSubscription;

  // Dynamic agent data extracted from messages
  String _mapboxToken = '';
  Map<String, dynamic>? _mapCenter;
  List<dynamic> _zones = [];
  List<dynamic> _events = [];
  bool _isScouting = false;
  String _currentAgent = "Orchestrator";
  String _statusMessage = "Analyzing brief...";
  bool _isComplete = false;
  bool _isDownloadingReport = false;
  bool _hasNavigatedToReport = false;

  // View toggle: Orchestration Graph (true) or Advisory Chatbox (false)
  bool _showGraph = true;
  int _selectedTabIndex = 0;

  static const List<String> _agentOrder = [
    "Orchestrator",
    "Location Scout",
    "Competitor Analyst",
    "Business Planner",
  ];

  @override
  void initState() {
    super.initState();
    _fetchMapboxToken();
    _connectToStream();
  }

  Future<void> _fetchMapboxToken() async {
    try {
      final token = await _apiService.getMapboxAccessToken();
      if (mounted) {
        setState(() {
          _mapboxToken = token;
        });
      }
    } catch (e) {
      print("[DEBUG] Error fetching mapbox token: $e");
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _connectToStream() {
    setState(() {
      _selectedTabIndex = 0;
      _zones.clear();
      _events.clear();
      _isScouting = true;
      _currentAgent = "Orchestrator";
      _statusMessage = "Starting Multi-Agent session...";
      _hasNavigatedToReport = false;
    });

    _streamSubscription = _apiService.streamRoomMessages(widget.roomId).listen(
      (message) {
        setState(() {
          _messages.add(message);
          _processMessageState(message);
        });
        _scrollToBottom();
      },
      onError: (err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Stream disconnected: $err")),
        );
      },
      onDone: () {
        setState(() {
          _isScouting = false;
        });
        _autoNavigateToReport();
      },
    );
  }

  void _processMessageState(RoomMessage msg) {
    if (msg.role == 'system') {
      final joinedAgent = _extractJoinedAgent(msg.content);
      if (joinedAgent != null) {
        _currentAgent = joinedAgent;
        _statusMessage = _agentTaskLabel(joinedAgent);
        _isScouting = true;
      }

      if (msg.content.contains("closed") || msg.content.contains("Complete")) {
        _isComplete = true;
        _isScouting = false;
        _statusMessage = "Analysis Complete";
        _autoNavigateToReport();
      }
      return;
    }

    if (_agentOrder.contains(msg.sender)) {
      _currentAgent = msg.sender;
    }

    if (msg.sender == 'Orchestrator') {
      _statusMessage = "Orchestrating agents...";
      _isScouting = true;
    } else if (msg.sender == 'Location Scout') {
      _statusMessage = "Scouting geographic zones...";
      _isScouting = true;
      if (msg.type == 'data') {
        _mapCenter = msg.data['center'];
        if (_zones.isEmpty || !_zones.first.containsKey('opp_score')) {
          _zones = List<dynamic>.from(msg.data['zones'] ?? []);
        }
        _events = List<dynamic>.from(msg.data['events'] ?? []);
      }
    } else if (msg.sender == 'Competitor Analyst') {
      _statusMessage = "Analyzing market saturation...";
      _isScouting = false;
      if (msg.type == 'data') {
        final enrichedZones = msg.data['enriched_zones'];
        if (enrichedZones != null) {
          _zones = List<dynamic>.from(enrichedZones);
        }
      }
    } else if (msg.sender == 'Business Planner') {
      _statusMessage = "Formulating business plan...";
      _isScouting = false;
      if (msg.type == 'data' && _zones.isEmpty) {
        final plannerZones = msg.data['zones'] ?? msg.data['enriched_zones'];
        if (plannerZones != null) {
          _zones = List<dynamic>.from(plannerZones);
        }
      }
    }
  }

  String? _extractJoinedAgent(String content) {
    for (final agent in _agentOrder) {
      if (content.contains("@$agent has joined")) {
        return agent;
      }
    }
    return null;
  }

  String _agentTaskLabel(String agent) {
    switch (agent) {
      case "Orchestrator":
        return "Orchestrating agents...";
      case "Location Scout":
        return "Scouting zones with Bright Data context...";
      case "Competitor Analyst":
        return "Analyzing market saturation...";
      case "Business Planner":
        return "Writing final plan and PDF...";
      default:
        return "Working...";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _autoNavigateToReport() {
    if (_hasNavigatedToReport) return;
    _hasNavigatedToReport = true;

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _downloadReport();
    });
  }

  Future<void> _downloadReport() async {
    if (_isDownloadingReport) return;

    setState(() {
      _isDownloadingReport = true;
    });

    try {
      if (mounted) {
        Map<String, dynamic>? reportData;
        for (final msg in _messages) {
          if (msg.sender == "Business Planner" && msg.type == "data") {
            reportData = msg.data;
            break;
          }
        }

        if (reportData == null && _zones.isNotEmpty) {
          reportData = _zones.first;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResearchReportScreen(
              roomId: widget.roomId,
              businessType: widget.businessType,
              city: widget.city,
              reportData: reportData,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open report: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingReport = false;
        });
      }
    }
  }

  Future<bool> _handleSendMessage(String content) async {
    return await _apiService.sendRoomMessage(
      widget.roomId,
      'User',
      'user',
      content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgWhite = const Color(0xFFFDFDFD);
    final cardWhite = Colors.white;
    final primaryGold = const Color(0xFF111111);
    final neonPink = const Color(0xFFFF187F);

    return ResponsiveWebWrapper(
      child: Scaffold(
        backgroundColor: bgWhite,
        appBar: AppBar(
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${widget.businessType} • ${widget.city}",
                style: GoogleFonts.outfit(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _isComplete ? const Color(0xFF10B981) : neonPink,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isComplete
                        ? "Consensus Reached"
                        : "$_currentAgent: $_statusMessage",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            ],
          ),
          actions: [
            if (_isComplete)
              TextButton.icon(
                onPressed: _isDownloadingReport ? null : _downloadReport,
                icon: _isDownloadingReport
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF187F),
                        ),
                      )
                    : const Icon(Icons.description,
                        color: Color(0xFFFF187F), size: 18),
                label: Text(
                  _isDownloadingReport ? "LOADING" : "READ REPORT",
                  style: const TextStyle(
                    color: Color(0xFFFF187F),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: primaryGold.withOpacity(0.2),
              height: 1.0,
            ),
          ),
        ),
        body: SafeArea(
        child: Column(
          children: [
            _buildTabSelector(primaryGold, neonPink),
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  _buildCollaborationFeed(cardWhite, primaryGold),
                  ScoutingResultsDashboard(
                    zones: _zones,
                    events: _events,
                    mapCenter: _mapCenter,
                    isScouting: _isScouting,
                    messages: _messages,
                    isDownloadingReport: _isDownloadingReport,
                    onDownloadReport: _downloadReport,
                    mapboxAccessToken: _mapboxToken,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),);
  }

  Widget _buildTabSelector(Color primaryGold, Color neonPink) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGold.withOpacity(0.3), width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 13,
                      color: _selectedTabIndex == 0 ? neonPink : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "COLLABORATION ROOM",
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: _selectedTabIndex == 0 ? Colors.black : Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 1;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 13,
                      color: _selectedTabIndex == 1 ? neonPink : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "CONSENSUS REPORT",
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: _selectedTabIndex == 1 ? Colors.black : Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (_zones.isNotEmpty && !_isComplete) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: neonPink,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaborationFeed(Color cardWhite, Color primaryGold) {
    return Column(
      children: [
        // View Selector Switch (Graph vs Chatbox)
        _buildViewToggle(),

        Expanded(
          child: _showGraph
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      BandOrchestrationGraph(
                        messages: _messages,
                        isComplete: _isComplete,
                        currentAgent: _currentAgent,
                        zones: _zones,
                        primaryGold: primaryGold,
                      ),
                      // Latest agent status card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF111111).withOpacity(0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFFFF187F)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "LATEST UPDATE",
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF187F),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _messages.isNotEmpty
                                        ? "@$_currentAgent: $_statusMessage"
                                        : "Waiting for room stream...",
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              : CollaborationChatbox(
                  roomId: widget.roomId,
                  messages: _messages,
                  scrollController: _scrollController,
                  onSendMessage: _handleSendMessage,
                  onOpenPdf: _downloadReport,
                ),
        ),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showGraph = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _showGraph ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _showGraph
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hub_outlined,
                      size: 13,
                      color: _showGraph ? const Color(0xFFFF187F) : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "ORCHESTRATION GRAPH",
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _showGraph ? Colors.black : Colors.grey[600],
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showGraph = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_showGraph ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: !_showGraph
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 13,
                      color: !_showGraph ? const Color(0xFFFF187F) : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "ADVISORY CHATBOX",
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: !_showGraph ? Colors.black : Colors.grey[600],
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasOrchestrationStage(String stage) {
    return _messages.any((msg) => msg.type == "orchestration" && msg.data['stage'] == stage);
  }


  String _agentState(String agent) {
    if (_messages.any((msg) => msg.sender == agent && msg.role != 'system')) {
      return "DONE";
    }
    if (!_isComplete && _currentAgent == agent) {
      return "WORKING";
    }
    return "WAITING";
  }

  Color _agentColor(String agent) {
    switch (agent) {
      case "Orchestrator":
        return const Color(0xFFFF187F);
      case "Location Scout":
        return const Color(0xFF111111);
      case "Competitor Analyst":
        return const Color(0xFF111111);
      case "Business Planner":
        return const Color(0xFFFF187F);
      default:
        return Colors.grey;
    }
  }

  IconData _agentIcon(String agent) {
    switch (agent) {
      case "Orchestrator":
        return Icons.settings_input_component_outlined;
      case "Location Scout":
        return Icons.map_outlined;
      case "Competitor Analyst":
        return Icons.analytics_outlined;
      case "Business Planner":
        return Icons.article_outlined;
      default:
        return Icons.smart_toy_outlined;
    }
  }

  String _agentRoleTag(String agent) {
    switch (agent) {
      case "Orchestrator":
        return "Coordinator";
      case "Location Scout":
        return "GIS + Bright Data";
      case "Competitor Analyst":
        return "Market Saturation";
      case "Business Planner":
        return "Strategy Architect";
      default:
        return "Agent";
    }
  }
}
