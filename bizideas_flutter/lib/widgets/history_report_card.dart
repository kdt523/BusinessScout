import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../screens/research_report_screen.dart';

class HistoryReportCard extends StatefulWidget {
  final String roomId;
  final String businessType;
  final String city;
  final String dateStr;
  final ApiService apiService;

  const HistoryReportCard({
    super.key,
    required this.roomId,
    required this.businessType,
    required this.city,
    required this.dateStr,
    required this.apiService,
  });

  @override
  State<HistoryReportCard> createState() => _HistoryReportCardState();
}

class _HistoryReportCardState extends State<HistoryReportCard> {
  bool _isDownloading = false;

  Future<void> _downloadAndOpenPdf() async {
    if (kIsWeb) {
      try {
        final url = widget.apiService.getPdfDownloadUrl(widget.roomId);
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to open PDF: $e")),
          );
        }
      }
      return;
    }

    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
    });

    try {
      final file = await widget.apiService.downloadPdfReport(widget.roomId);
      final result = await OpenFilex.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.type == ResultType.done
                  ? "Report saved and opened successfully."
                  : "Report saved at ${file.path}.",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to download PDF: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryGold = const Color(0xFFECC870);
    final neonPink = const Color(0xFFFF187F);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResearchReportScreen(
              roomId: widget.roomId,
              businessType: widget.businessType,
              city: widget.city,
              reportData: null,
            ),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: primaryGold.withOpacity(0.2),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: neonPink.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                color: neonPink,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.businessType,
                    style: GoogleFonts.outfit(
                      color: Colors.black,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.city,
                    style: GoogleFonts.outfit(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Generated: ${widget.dateStr}",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _downloadAndOpenPdf,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFFFF187F)),
                    )
                  : const Icon(
                      Icons.download_rounded,
                      color: Color(0xFFFF187F),
                      size: 20,
                    ),
              style: IconButton.styleFrom(
                backgroundColor: neonPink.withOpacity(0.08),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
