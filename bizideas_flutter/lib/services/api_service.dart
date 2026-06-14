import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/room_message.dart';

class ApiService {
  // TODO: Set this to your own backend server URL before deploying.
  // Example: 'http://your-server-ip-or-domain'
  // For local development: 'http://localhost:8000'
  static String get baseUrl => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8000',
      );

  String? _mapboxAccessToken;

  /// Fetches the Mapbox Access Token dynamically from the backend configuration.
  Future<String> getMapboxAccessToken() async {
    if (_mapboxAccessToken != null) return _mapboxAccessToken!;
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/config/mapbox'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _mapboxAccessToken = data['accessToken'];
        return _mapboxAccessToken ?? '';
      }
    } catch (e) {
      print('Error fetching Mapbox token: $e');
    }
    return '';
  }

  final http.Client _client = http.Client();

  /// Creates a new multi-agent room and triggers the Orchestrator agent.
  Future<String> createAnalysisRoom(
    String businessType,
    String city, {
    String? userLocale,
    String? userCountry,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/rooms/create'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'business_type': businessType,
        'city': city,
        'user_locale': userLocale,
        'user_country': userCountry,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['room_id'];
    } else {
      throw Exception('Failed to initiate agent room: ${response.statusCode}');
    }
  }

  /// Establishes a real-time connection to the agent room using Server-Sent Events (SSE).
  Stream<RoomMessage> streamRoomMessages(String roomId) {
    final controller = StreamController<RoomMessage>();
    final request =
        http.Request('GET', Uri.parse('$baseUrl/api/rooms/$roomId/stream'));
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Cache-Control'] = 'no-cache';

    _client.send(request).then((response) {
      if (response.statusCode != 200) {
        controller.addError(
            Exception('Failed to connect to stream: ${response.statusCode}'));
        controller.close();
        return;
      }

      // Stream subscriber
      late StreamSubscription subscription;

      subscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isNotEmpty) {
              try {
                final Map<String, dynamic> jsonMap = json.decode(jsonStr);
                final message = RoomMessage.fromJson(jsonMap);
                controller.add(message);
              } catch (e) {
                // Ignore ping keep-alives or non-JSON payloads
                print('SSE parse warning: $e');
              }
            }
          }
        },
        onError: (err) {
          controller.addError(err);
          controller.close();
        },
        onDone: () {
          controller.close();
        },
        cancelOnError: true,
      );

      controller.onCancel = () {
        subscription.cancel();
      };
    }).catchError((err) {
      controller.addError(err);
      controller.close();
    });

    return controller.stream;
  }

  /// Returns the endpoint URL to download the business plan report PDF.
  String getPdfDownloadUrl(String roomId) {
    return '$baseUrl/api/rooms/$roomId/pdf';
  }

  /// Downloads the generated PDF into app-local storage and returns the file.
  Future<dynamic> downloadPdfReport(String roomId) async {
    if (kIsWeb) {
      return null;
    }
    final response = await _client.get(Uri.parse(getPdfDownloadUrl(roomId)));
    if (response.statusCode != 200) {
      throw Exception('Report is not ready yet (${response.statusCode}).');
    }

    final directory = await getApplicationDocumentsDirectory();
    final reportsDir =
        Directory('${directory.path}${Platform.pathSeparator}BScoutReports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final safeRoomId = roomId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File(
        '${reportsDir.path}${Platform.pathSeparator}BScout_$safeRoomId.pdf');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }

  /// Fetches a list of past generated reports from the backend.
  Future<List<Map<String, dynamic>>> fetchReportsHistory() async {
    final response = await http.get(Uri.parse('$baseUrl/api/reports'));
    if (response.statusCode == 200) {
      final List<dynamic> list = json.decode(response.body);
      return list.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      throw Exception('Failed to fetch reports history: ${response.statusCode}');
    }
  }

  /// Fetches the Opportunity Index for a specific room.
  /// Returns the opportunity index value if available, or null on failure.
  Future<double?> getOpportunityIndex(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rooms/$roomId/opportunity_index'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final opportunityIndex = data['opportunity_index'];
        
        // Handle both int and double types
        if (opportunityIndex is num) {
          return opportunityIndex.toDouble();
        }
        return null;
      } else {
        // Return null on non-200 status codes
        return null;
      }
    } catch (e) {
      // Return null on any errors (network, parsing, etc.)
      print('Error fetching opportunity index: $e');
      return null;
    }
  }

  /// Fetches historical messages for a room to reconstruct the research report.
  Future<List<RoomMessage>> getRoomMessages(String roomId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/rooms/$roomId/messages'));
    if (response.statusCode == 200) {
      final List<dynamic> list = json.decode(response.body);
      return list.map((item) => RoomMessage.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch room messages: ${response.statusCode}');
    }
  }

  /// Sends a custom message to the room to prompt research or converse.
  Future<bool> sendRoomMessage(
    String roomId,
    String sender,
    String role,
    String content,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/$roomId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender': sender,
          'role': role,
          'content': content,
          'type': 'text',
          'data': {},
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error sending room message: $e');
      return false;
    }
  }
}

