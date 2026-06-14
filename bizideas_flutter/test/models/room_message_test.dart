import 'package:flutter_test/flutter_test.dart';
import 'package:bizideas_flutter/models/room_message.dart';

void main() {
  group('RoomMessage', () {
    group('opportunityIndex field', () {
      test('should parse valid opportunityIndex from JSON', () {
        // Arrange
        final json = {
          'id': 'test-id',
          'sender': 'Test Sender',
          'role': 'agent',
          'content': 'Test content',
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'data',
          'data': {},
          'opportunity_index': 75.5,
        };

        // Act
        final message = RoomMessage.fromJson(json);

        // Assert
        expect(message.opportunityIndex, equals(75.5));
      });

      test('should handle null opportunityIndex in JSON', () {
        // Arrange
        final json = {
          'id': 'test-id',
          'sender': 'Test Sender',
          'role': 'agent',
          'content': 'Test content',
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'data',
          'data': {},
        };

        // Act
        final message = RoomMessage.fromJson(json);

        // Assert
        expect(message.opportunityIndex, isNull);
      });

      test('should handle explicit null opportunityIndex in JSON', () {
        // Arrange
        final json = {
          'id': 'test-id',
          'sender': 'Test Sender',
          'role': 'agent',
          'content': 'Test content',
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'data',
          'data': {},
          'opportunity_index': null,
        };

        // Act
        final message = RoomMessage.fromJson(json);

        // Assert
        expect(message.opportunityIndex, isNull);
      });

      test('should include opportunityIndex in toJson with valid value', () {
        // Arrange
        final message = RoomMessage(
          id: 'test-id',
          sender: 'Test Sender',
          role: 'agent',
          content: 'Test content',
          timestamp: DateTime.now(),
          type: 'data',
          data: {},
          opportunityIndex: 85.3,
        );

        // Act
        final json = message.toJson();

        // Assert
        expect(json['opportunity_index'], equals(85.3));
      });

      test('should include null opportunityIndex in toJson when not provided', () {
        // Arrange
        final message = RoomMessage(
          id: 'test-id',
          sender: 'Test Sender',
          role: 'agent',
          content: 'Test content',
          timestamp: DateTime.now(),
          type: 'data',
          data: {},
        );

        // Act
        final json = message.toJson();

        // Assert
        expect(json['opportunity_index'], isNull);
      });

      test('should handle integer opportunityIndex values', () {
        // Arrange
        final json = {
          'id': 'test-id',
          'sender': 'Test Sender',
          'role': 'agent',
          'content': 'Test content',
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'data',
          'data': {},
          'opportunity_index': 75,
        };

        // Act
        final message = RoomMessage.fromJson(json);

        // Assert
        expect(message.opportunityIndex, equals(75.0));
      });

      test('should round-trip serialize and deserialize with opportunityIndex', () {
        // Arrange
        final originalMessage = RoomMessage(
          id: 'test-id',
          sender: 'Test Sender',
          role: 'agent',
          content: 'Test content',
          timestamp: DateTime.parse('2024-01-15T10:30:00.000Z'),
          type: 'data',
          data: {'key': 'value'},
          opportunityIndex: 92.7,
        );

        // Act
        final json = originalMessage.toJson();
        final deserializedMessage = RoomMessage.fromJson(json);

        // Assert
        expect(deserializedMessage.opportunityIndex, equals(92.7));
        expect(deserializedMessage.id, equals(originalMessage.id));
        expect(deserializedMessage.sender, equals(originalMessage.sender));
      });
    });
  });
}
