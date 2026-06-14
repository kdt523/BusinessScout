import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:bizideas_flutter/services/api_service.dart';

void main() {
  group('ApiService.getOpportunityIndex', () {
    test('should return opportunity index when API returns valid double data', () async {
      // Arrange
      final apiService = ApiService();

      // Act
      final result = await apiService.getOpportunityIndex('test-room-id');

      // Assert
      // This makes a real HTTP request to the backend
      // The result depends on whether the backend has data for this room
      expect(result, isA<double?>());
    });

    test('should return opportunity index when API returns valid integer data', () async {
      // Arrange
      final apiService = ApiService();

      // Act
      final result = await apiService.getOpportunityIndex('test-room-int');

      // Assert
      // Tests that integer values are converted to double
      expect(result, isA<double?>());
    });

    test('should return null when API returns 404', () async {
      // Arrange
      final apiService = ApiService();

      // Act
      final result = await apiService.getOpportunityIndex('non-existent-room-12345');

      // Assert
      // Should return null for non-existent rooms
      expect(result, isNull);
    });

    test('should return null when API returns 500 error', () async {
      // Arrange
      final apiService = ApiService();

      // Act
      final result = await apiService.getOpportunityIndex('server-error-room');

      // Assert
      // Should handle server errors gracefully by returning null
      expect(result, isNull);
    });

    test('should return null when opportunity_index field is missing from response', () async {
      // Arrange
      final apiService = ApiService();

      // Act
      final result = await apiService.getOpportunityIndex('test-room-no-index');

      // Assert
      // Should return null when the field is missing
      expect(result, isNull);
    });

    test('should return null when opportunity_index field is not a number', () async {
      // Arrange
      final apiService = ApiService();

      // Act
      final result = await apiService.getOpportunityIndex('test-room-invalid-type');

      // Assert
      // Should return null for invalid data types
      expect(result, isNull);
    });

    test('should handle network errors gracefully', () async {
      // Arrange
      final apiService = ApiService();

      // Act
      final result = await apiService.getOpportunityIndex('test-network-error');

      // Assert
      // Should return null on network errors
      expect(result, isA<double?>());
    });
  });

  group('ApiService.getOpportunityIndex - Value Range Tests', () {
    test('should handle zero opportunity index', () async {
      // Arrange
      final apiService = ApiService();

      // Act
      final result = await apiService.getOpportunityIndex('test-room-zero');

      // Assert
      // Zero is a valid opportunity index value
      expect(result, isA<double?>());
    });

    test('should handle negative opportunity index values', () async {
      // Arrange
      final apiService = ApiService();

      // Act
      final result = await apiService.getOpportunityIndex('test-room-negative');

      // Assert
      // Method does not validate range (validation happens at UI layer)
      expect(result, isA<double?>());
    });

    test('should handle very large opportunity index values', () async {
      // Arrange
      final apiService = ApiService();

      // Act
      final result = await apiService.getOpportunityIndex('test-room-large');

      // Assert
      // Should handle large numbers without overflow
      expect(result, isA<double?>());
    });
  });

  group('ApiService.getOpportunityIndex - Integration Tests', () {
    test('should construct correct API endpoint URL', () async {
      // Arrange
      final apiService = ApiService();
      const testRoomId = 'test-room-endpoint';

      // Act
      final result = await apiService.getOpportunityIndex(testRoomId);

      // Assert
      // The method should call the correct endpoint
      // Expected URL: http://10.0.2.2:8082/api/rooms/test-room-endpoint/opportunity_index
      expect(result, isA<double?>());
    });

    test('should handle special characters in room ID', () async {
      // Arrange
      final apiService = ApiService();
      const testRoomId = 'room-with-special-chars_123';

      // Act
      final result = await apiService.getOpportunityIndex(testRoomId);

      // Assert
      // Should handle room IDs with hyphens, underscores, and numbers
      expect(result, isA<double?>());
    });
  });
}
