import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/room_message.dart';
import 'bezier_connectors.dart';
import 'agent_graph_node.dart';

class BandOrchestrationGraph extends StatelessWidget {
  final List<RoomMessage> messages;
  final bool isComplete;
  final String currentAgent;
  final List<dynamic> zones;
  final Color primaryGold;

  const BandOrchestrationGraph({
    super.key,
    required this.messages,
    required this.isComplete,
    required this.currentAgent,
    required this.zones,
    required this.primaryGold,
  });

  bool _hasOrchestrationStage(String stage) {
    return messages.any((msg) => msg.type == "orchestration" && msg.data['stage'] == stage);
  }

  Color _agentColor(String agent) {
    switch (agent) {
      case "Orchestrator":
        return const Color(0xFFFF187F);
      case "Location Scout":
        return const Color(0xFFC59F4A);
      case "Competitor Analyst":
        return const Color(0xFF111111);
      case "Business Planner":
        return const Color(0xFFECC870);
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

  Widget _buildConsensusNode(bool consensusReady) {
    final color = consensusReady ? const Color(0xFF10B981) : const Color(0xFF64748B);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: consensusReady ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: consensusReady ? const Color(0xFF10B981).withOpacity(0.6) : const Color(0xFFE2E8F0),
          width: consensusReady ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: consensusReady ? const Color(0xFF10B981).withOpacity(0.04) : Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: consensusReady ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
              border: Border.all(
                color: consensusReady ? const Color(0xFF6EE7B7) : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: Icon(
              consensusReady ? Icons.verified_user_rounded : Icons.picture_as_pdf_outlined,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consensusReady ? "Consensus Finalized" : "Awaiting Consensus",
                  style: GoogleFonts.outfit(
                    color: consensusReady ? const Color(0xFF065F46) : const Color(0xFF334155),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  consensusReady
                      ? "The decision coordinates are resolved and the Business Plan PDF is published."
                      : "The final PDF report will generate automatically when all work packages compile.",
                  style: TextStyle(
                    color: consensusReady ? const Color(0xFF047857) : const Color(0xFF64748B),
                    fontSize: 8.5,
                    height: 1.25,
                    fontWeight: consensusReady ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomOpen = _hasOrchestrationStage("room_open") || messages.isNotEmpty;
    final contextReady = _hasOrchestrationStage("shared_context_ready") ||
        messages.any((msg) => msg.sender == "Orchestrator");
    final parallelStarted = _hasOrchestrationStage("parallel_handoff") ||
        messages.any((msg) => msg.content.contains("Parallel research started"));
    final locationReady = _hasOrchestrationStage("location_package_ready") ||
        messages.any((msg) => msg.sender == "Location Scout" && msg.type == "data");
    final competitorReady = _hasOrchestrationStage("competitor_package_ready") ||
        messages.any((msg) => msg.sender == "Competitor Analyst" && msg.type == "data");
    final mergeReady = _hasOrchestrationStage("merge_handoff") ||
        messages.any((msg) => msg.content.contains("Parallel research complete"));
    final plannerReady = _hasOrchestrationStage("planner_synthesis_ready") ||
        messages.any((msg) => msg.sender == "Business Planner" && msg.type == "data");
    final consensusReady = _hasOrchestrationStage("consensus_closed") || isComplete;
    final eventCount = messages.where((msg) => msg.type == "orchestration").length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: primaryGold.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF187F).withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF187F).withOpacity(0.2),
                  ),
                ),
                child: const Icon(Icons.hub_outlined, color: Color(0xFFFF187F), size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ORCHESTRATION NETWORK",
                      style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$eventCount network transmission${eventCount == 1 ? '' : 's'} recorded",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: consensusReady ? const Color(0xFFDCFCE7) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: consensusReady ? const Color(0xFF86EFAC) : const Color(0xFFFECDD3),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!consensusReady) ...[
                      const Icon(Icons.sync, color: Color(0xFFE11D48), size: 10),
                      const SizedBox(width: 5),
                      Text(
                        "LIVE PIPELINE",
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFE11D48),
                          fontSize: 7.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 10),
                      const SizedBox(width: 4),
                      Text(
                        "COMPLETE",
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF15803D),
                          fontSize: 7.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final nodeWidth = (constraints.maxWidth - 12) / 2;
              return Column(
                children: [
                  AgentGraphNode(
                    agent: "Orchestrator",
                    title: "1. Recruit & Context",
                    subtitle: contextReady
                        ? "Shared context package published."
                        : roomOpen
                            ? "Acquiring coordinator role..."
                            : "Waiting for room stream...",
                    active: roomOpen && !contextReady,
                    done: contextReady,
                    width: constraints.maxWidth,
                    color: _agentColor("Orchestrator"),
                    icon: _agentIcon("Orchestrator"),
                    roleTag: _agentRoleTag("Orchestrator"),
                  ),
                  SplitBezierConnector(
                    activeLeft: parallelStarted && !locationReady,
                    activeRight: parallelStarted && !competitorReady,
                    doneLeft: locationReady,
                    doneRight: competitorReady,
                    colorLeft: _agentColor("Location Scout"),
                    colorRight: _agentColor("Competitor Analyst"),
                    colorParent: _agentColor("Orchestrator"),
                    nodeWidth: nodeWidth,
                    label: "CONTEXT BROADCAST",
                  ),
                  Row(
                    children: [
                      AgentGraphNode(
                        agent: "Location Scout",
                        title: "2A. Geographic Scout",
                        subtitle: locationReady
                            ? "Zones resolved."
                            : parallelStarted
                                ? "Scouting commercial zones..."
                                : "Awaiting dispatch...",
                        active: parallelStarted && !locationReady,
                        done: locationReady,
                        width: nodeWidth,
                        color: _agentColor("Location Scout"),
                        icon: _agentIcon("Location Scout"),
                        roleTag: _agentRoleTag("Location Scout"),
                      ),
                      const SizedBox(width: 12),
                      AgentGraphNode(
                        agent: "Competitor Analyst",
                        title: "2B. Market Saturation",
                        subtitle: competitorReady
                            ? "Opportunity indexed."
                            : parallelStarted
                                ? "Evaluating saturation..."
                                : "Awaiting dispatch...",
                        active: parallelStarted && !competitorReady,
                        done: competitorReady,
                        width: nodeWidth,
                        color: _agentColor("Competitor Analyst"),
                        icon: _agentIcon("Competitor Analyst"),
                        roleTag: _agentRoleTag("Competitor Analyst"),
                      ),
                    ],
                  ),
                  MergeBezierConnector(
                    activeLeft: locationReady,
                    activeRight: competitorReady,
                    doneLeft: locationReady,
                    doneRight: competitorReady,
                    parentActive: mergeReady && !plannerReady,
                    colorLeft: _agentColor("Location Scout"),
                    colorRight: _agentColor("Competitor Analyst"),
                    colorParent: _agentColor("Business Planner"),
                    nodeWidth: nodeWidth,
                    label: mergeReady ? "PACKAGES MERGED" : "PARALLEL INGEST",
                  ),
                  AgentGraphNode(
                    agent: "Business Planner",
                    title: "3. Decision Synthesis",
                    subtitle: plannerReady
                        ? "Feasibility PDF compiled."
                        : mergeReady
                            ? "Synthesizing plans..."
                            : "Waiting for research stream...",
                    active: mergeReady && !plannerReady,
                    done: plannerReady,
                    width: constraints.maxWidth,
                    color: _agentColor("Business Planner"),
                    icon: _agentIcon("Business Planner"),
                    roleTag: _agentRoleTag("Business Planner"),
                  ),
                  StraightBezierConnector(
                    active: plannerReady && !consensusReady,
                    done: consensusReady,
                    color: const Color(0xFF10B981),
                    label: "PUBLISH DELIVERABLE",
                  ),
                  _buildConsensusNode(consensusReady),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
