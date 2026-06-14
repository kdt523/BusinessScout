import 'package:flutter/material.dart';

class CompetitorChart extends StatelessWidget {
  final List<dynamic> zones;

  const CompetitorChart({
    super.key,
    required this.zones,
  });

  @override
  Widget build(BuildContext context) {
    if (zones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Location Feasibility Score Comparison",
          style: TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(zones.length, (index) {
          final zone = zones[index];
          final double traffic = (zone['traffic_score'] ?? 0.0) as double;
          final double saturation = (zone['saturation_score'] ?? 0.0) as double;
          final double oppScore = (zone['opp_score'] ?? 0.0) as double;
          final int competitors = zone['competitor_count'] ?? 0;

          final Color scoreColor = index == 0
              ? const Color(0xFFFF187F) // Neon Pink for rank 1
              : const Color(0xFFECC870); // Light Gold for others

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: index == 0 ? const Color(0xFFFF187F).withOpacity(0.4) : const Color(0xFFECC870).withOpacity(0.25),
                width: index == 0 ? 1.5 : 1.0,
              ),
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
                // Opportunity Score Circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: index == 0 ? const Color(0x0FFF187F) : const Color(0x0FECC870),
                    shape: BoxShape.circle,
                    border: Border.all(color: scoreColor, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        oppScore.toStringAsFixed(1),
                        style: TextStyle(
                          color: index == 0 ? const Color(0xFFFF187F) : const Color(0xFFC59F4A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "INDEX",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 6,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Details and Progress Bars
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "#${index + 1} ${zone['name']}",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "$competitors Competitors",
                            style: TextStyle(
                              color: saturation >= 7.0 
                                  ? const Color(0xFFFF187F) 
                                  : saturation >= 4.0 
                                      ? const Color(0xFFC59F4A) 
                                      : const Color(0xFF10B981),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Foot Traffic Bar
                      Row(
                        children: [
                          const SizedBox(
                            width: 75,
                            child: Text(
                              "Foot Traffic:",
                              style: TextStyle(color: Colors.grey, fontSize: 9),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: traffic / 10.0,
                                backgroundColor: const Color(0xFFF1F1F1),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFECC870)),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${traffic.toStringAsFixed(1)}/10",
                            style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Saturation Bar
                      Row(
                        children: [
                          const SizedBox(
                            width: 75,
                            child: Text(
                              "Saturation:",
                              style: TextStyle(color: Colors.grey, fontSize: 9),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: saturation / 10.0,
                                backgroundColor: const Color(0xFFF1F1F1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  saturation >= 7.0 
                                      ? const Color(0xFFFF187F) 
                                      : saturation >= 4.0 
                                          ? const Color(0xFFECC870) 
                                          : const Color(0xFF10B981)
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${saturation.toStringAsFixed(1)}/10",
                            style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
