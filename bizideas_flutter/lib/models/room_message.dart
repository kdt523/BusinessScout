class RoomMessage {
  final String id;
  final String sender;
  final String role;
  final String content;
  final DateTime timestamp;
  final String type;
  final Map<String, dynamic> data;
  final double? opportunityIndex;

  RoomMessage({
    required this.id,
    required this.sender,
    required this.role,
    required this.content,
    required this.timestamp,
    required this.type,
    required this.data,
    this.opportunityIndex,
  });

  factory RoomMessage.fromJson(Map<String, dynamic> json) {
    return RoomMessage(
      id: json['id'] ?? '',
      sender: json['sender'] ?? 'System',
      role: json['role'] ?? 'system',
      content: _sanitizeUnicode(json['content'] ?? ''),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIsoformatString()),
      type: json['type'] ?? 'text',
      data: Map<String, dynamic>.from(_sanitizeObject(json['data'] ?? {})),
      opportunityIndex: json['opportunity_index'] != null 
          ? (json['opportunity_index'] as num).toDouble() 
          : null,
    );
  }

  static dynamic _sanitizeObject(dynamic obj) {
    if (obj is String) {
      return _sanitizeUnicode(obj);
    } else if (obj is Map) {
      return obj.map((key, value) => MapEntry(key.toString(), _sanitizeObject(value)));
    } else if (obj is List) {
      return obj.map((item) => _sanitizeObject(item)).toList();
    }
    return obj;
  }

  static String _sanitizeUnicode(String input) {
    try {
      final codeUnits = input.codeUnits;
      final cleanCodeUnits = <int>[];
      for (int i = 0; i < codeUnits.length; i++) {
        int char = codeUnits[i];
        if (char >= 0xD800 && char <= 0xDBFF) {
          // High surrogate
          if (i + 1 < codeUnits.length) {
            int next = codeUnits[i + 1];
            if (next >= 0xDC00 && next <= 0xDFFF) {
              cleanCodeUnits.add(char);
              cleanCodeUnits.add(next);
              i++;
              continue;
            }
          }
          continue; // Skip unpaired high surrogate
        } else if (char >= 0xDC00 && char <= 0xDFFF) {
          continue; // Skip unpaired low surrogate
        }
        cleanCodeUnits.add(char);
      }
      return String.fromCharCodes(cleanCodeUnits);
    } catch (_) {
      return input;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'data': data,
      'opportunity_index': opportunityIndex,
    };
  }
}
extension on DateTime {
  String toIsoformatString() => toUtc().toIso8601String();
}
