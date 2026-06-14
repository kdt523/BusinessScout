import 'package:flutter_test/flutter_test.dart';
import 'package:bizideas_flutter/models/research_history_item.dart';

void main() {
  group('ResearchHistoryItem', () {
    test('should create a valid ResearchHistoryItem instance', () {
      final item = ResearchHistoryItem(
        roomId: 'test-room-123',
        businessType: 'Coffee Shop',
        city: 'Seattle',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        opportunityIndex: 85.5,
        pdfFilePath: '/path/to/report.pdf',
        isPdfCached: true,
      );

      expect(item.roomId, 'test-room-123');
      expect(item.businessType, 'Coffee Shop');
      expect(item.city, 'Seattle');
      expect(item.timestamp, DateTime(2024, 1, 15, 10, 30));
      expect(item.opportunityIndex, 85.5);
      expect(item.pdfFilePath, '/path/to/report.pdf');
      expect(item.isPdfCached, true);
    });

    test('should serialize to JSON correctly', () {
      final item = ResearchHistoryItem(
        roomId: 'test-room-456',
        businessType: 'Restaurant',
        city: 'Portland',
        timestamp: DateTime(2024, 2, 20, 14, 45),
        opportunityIndex: 72.3,
        pdfFilePath: '/cached/report.pdf',
        isPdfCached: true,
      );

      final json = item.toJson();

      expect(json['room_id'], 'test-room-456');
      expect(json['business_type'], 'Restaurant');
      expect(json['city'], 'Portland');
      expect(json['timestamp'], '2024-02-20T14:45:00.000');
      expect(json['opportunity_index'], 72.3);
      expect(json['pdf_file_path'], '/cached/report.pdf');
      expect(json['is_pdf_cached'], true);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'room_id': 'test-room-789',
        'business_type': 'Gym',
        'city': 'Austin',
        'timestamp': '2024-03-10T09:15:00.000',
        'opportunity_index': 90.0,
        'pdf_file_path': '/downloads/gym_report.pdf',
        'is_pdf_cached': false,
      };

      final item = ResearchHistoryItem.fromJson(json);

      expect(item.roomId, 'test-room-789');
      expect(item.businessType, 'Gym');
      expect(item.city, 'Austin');
      expect(item.timestamp, DateTime(2024, 3, 10, 9, 15));
      expect(item.opportunityIndex, 90.0);
      expect(item.pdfFilePath, '/downloads/gym_report.pdf');
      expect(item.isPdfCached, false);
    });

    test('should handle null opportunityIndex', () {
      final item = ResearchHistoryItem(
        roomId: 'test-room-null',
        businessType: 'Bakery',
        city: 'Denver',
        timestamp: DateTime(2024, 4, 5, 8, 0),
        opportunityIndex: null,
        pdfFilePath: null,
        isPdfCached: false,
      );

      final json = item.toJson();
      expect(json['opportunity_index'], null);
      expect(json['pdf_file_path'], null);

      final deserializedItem = ResearchHistoryItem.fromJson(json);
      expect(deserializedItem.opportunityIndex, null);
      expect(deserializedItem.pdfFilePath, null);
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'room_id': 'test-room-minimal',
        'business_type': 'Bookstore',
        'city': 'Boston',
        'timestamp': '2024-05-01T12:00:00.000',
      };

      final item = ResearchHistoryItem.fromJson(json);

      expect(item.roomId, 'test-room-minimal');
      expect(item.businessType, 'Bookstore');
      expect(item.city, 'Boston');
      expect(item.timestamp, DateTime(2024, 5, 1, 12, 0));
      expect(item.opportunityIndex, null);
      expect(item.pdfFilePath, null);
      expect(item.isPdfCached, false);
    });

    test('should serialize and deserialize round-trip correctly', () {
      final original = ResearchHistoryItem(
        roomId: 'roundtrip-test',
        businessType: 'Cafe',
        city: 'San Francisco',
        timestamp: DateTime(2024, 6, 15, 16, 30),
        opportunityIndex: 68.2,
        pdfFilePath: '/path/to/cafe.pdf',
        isPdfCached: true,
      );

      final json = original.toJson();
      final deserialized = ResearchHistoryItem.fromJson(json);

      expect(deserialized.roomId, original.roomId);
      expect(deserialized.businessType, original.businessType);
      expect(deserialized.city, original.city);
      expect(deserialized.timestamp, original.timestamp);
      expect(deserialized.opportunityIndex, original.opportunityIndex);
      expect(deserialized.pdfFilePath, original.pdfFilePath);
      expect(deserialized.isPdfCached, original.isPdfCached);
    });

    test('should use default value for isPdfCached when not provided', () {
      final item = ResearchHistoryItem(
        roomId: 'default-test',
        businessType: 'Salon',
        city: 'Miami',
        timestamp: DateTime(2024, 7, 20, 10, 0),
      );

      expect(item.isPdfCached, false);
    });
  });
}
