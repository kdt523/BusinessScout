import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResearchLandAcquisitionCard extends StatelessWidget {
  final List<dynamic> landResearch;
  final Map<String, dynamic> marketProfile;
  final Color primaryGold;
  final Color neonPink;

  const ResearchLandAcquisitionCard({
    super.key,
    required this.landResearch,
    required this.marketProfile,
    required this.primaryGold,
    required this.neonPink,
  });

  @override
  Widget build(BuildContext context) {
    if (landResearch.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencySymbol = marketProfile['currency_symbol'] ?? '\$';

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
                child: Icon(Icons.business_rounded, color: primaryGold, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'SITE & LAND ACQUISITION',
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
          
          ...landResearch.map((item) {
            final String zoneName = item['zone_name'] ?? 'Primary Corridor';
            final String decision = item['decision'] ?? 'Validation Needed';
            final double rent = (item['estimated_rent_php_month'] ?? 0.0).toDouble();
            final double buy = (item['estimated_land_purchase_php'] ?? 0.0).toDouble();
            final double lat = (item['lat'] ?? 0.0).toDouble();
            final double lng = (item['lng'] ?? 0.0).toDouble();
            final String source = item['source'] ?? 'Bright Data';
            final int listingsCount = (item['listings'] as List?)?.length ?? 0;

            final String rentStr = rent > 0 
                ? '$currencySymbol${_formatAmount(rent)} / mo'
                : 'N/A';
            final String buyStr = buy > 0
                ? '$currencySymbol${_formatAmount(buy)}'
                : 'N/A';

            final isRecommended = decision.toLowerCase().contains('buy') || decision.toLowerCase().contains('lease');
            final Color badgeColor = isRecommended ? const Color(0xFF10B981) : Colors.grey;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          zoneName,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          decision.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: badgeColor,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  
                  // Lease vs Buy Pricing Boxes
                  Row(
                    children: [
                      Expanded(
                        child: _buildPriceBox(
                          label: 'Estimated Lease',
                          price: rentStr,
                          color: const Color(0xFF3B82F6),
                          icon: Icons.calendar_today_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPriceBox(
                          label: 'Estimated Purchase',
                          price: buyStr,
                          color: const Color(0xFF8B5CF6),
                          icon: Icons.home_work_rounded,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 12),
                  
                  // Location details & Coordinates
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined, color: Colors.grey[500], size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$listingsCount listing${listingsCount == 1 ? '' : 's'} verified ($source)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[550],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          })
        ],
      ),
    );
  }

  Widget _buildPriceBox({
    required String label,
    required String price,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.005),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[450],
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              price,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
