class ResearchHistoryItem {
  final String roomId;
  final String businessType;
  final String city;
  final DateTime timestamp;
  final double? opportunityIndex;
  final String? pdfFilePath;
  final bool isPdfCached;

  ResearchHistoryItem({
    required this.roomId,
    required this.businessType,
    required this.city,
    required this.timestamp,
    this.opportunityIndex,
    this.pdfFilePath,
    this.isPdfCached = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'business_type': businessType,
      'city': city,
      'timestamp': timestamp.toIso8601String(),
      'opportunity_index': opportunityIndex,
      'pdf_file_path': pdfFilePath,
      'is_pdf_cached': isPdfCached,
    };
  }

  factory ResearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return ResearchHistoryItem(
      roomId: json['room_id'] as String,
      businessType: json['business_type'] as String,
      city: json['city'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      opportunityIndex: json['opportunity_index'] as double?,
      pdfFilePath: json['pdf_file_path'] as String?,
      isPdfCached: json['is_pdf_cached'] as bool? ?? false,
    );
  }
}
