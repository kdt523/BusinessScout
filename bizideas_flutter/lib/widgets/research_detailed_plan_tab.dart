import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'markdown_text.dart';

class ResearchDetailedPlanTab extends StatelessWidget {
  final Map<String, dynamic> planDetails;
  final Color primaryGold;
  final Color neonPink;

  const ResearchDetailedPlanTab({
    super.key,
    required this.planDetails,
    required this.primaryGold,
    required this.neonPink,
  });

  @override
  Widget build(BuildContext context) {
    final hasSummary = planDetails.containsKey('executive_summary');
    final hasUvp = planDetails.containsKey('uvp');
    final hasFinancials = planDetails.containsKey('financials');
    final hasMarketing = planDetails.containsKey('marketing');
    final hasFullPlan = planDetails.containsKey('full_plan');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasSummary) ...[
          _buildPlanCard(
            title: 'Executive Summary',
            icon: Icons.assignment_outlined,
            content: planDetails['executive_summary'].toString(),
            accentColor: neonPink,
          ),
          const SizedBox(height: 16),
        ],
        if (hasUvp) ...[
          _buildPlanCard(
            title: 'Unique Value Proposition',
            icon: Icons.star_outline_rounded,
            content: planDetails['uvp'].toString(),
            accentColor: primaryGold,
          ),
          const SizedBox(height: 16),
        ],
        if (hasFinancials) ...[
          _buildPlanCard(
            title: 'Year 1 Financial Targets',
            icon: Icons.monetization_on_outlined,
            content: planDetails['financials'].toString(),
            accentColor: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 16),
        ],
        if (hasMarketing) ...[
          _buildPlanCard(
            title: 'Marketing & Launch Strategy',
            icon: Icons.rocket_launch_outlined,
            content: planDetails['marketing'].toString(),
            accentColor: const Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
        ],
        if (hasFullPlan) ...[
          _buildFullPlanBlueprint(
            title: 'Complete Strategic Feasibility Plan',
            icon: Icons.description_outlined,
            content: planDetails['full_plan'].toString(),
            accentColor: neonPink,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildPlanCard({
    required String title,
    required IconData icon,
    required String content,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: primaryGold.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accentColor, width: 5.0),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey[850],
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 14),
              MarkdownText(
                text: content,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullPlanBlueprint({
    required String title,
    required IconData icon,
    required String content,
    required Color accentColor,
  }) {
    const blueprintBg = Color(0xFFF8FAFC);
    const borderBlue = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: blueprintBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderBlue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withOpacity(0.2)),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey[900],
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Synthesized AI Agent Consensus Plan',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDF2F7)),
            ),
            child: MarkdownText(
              text: content,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12.2,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
