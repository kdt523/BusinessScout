import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/room_message.dart';
import './chatbox_helpers.dart';

class CollaborationChatbox extends StatefulWidget {
  final String roomId;
  final List<RoomMessage> messages;
  final ScrollController scrollController;
  final Future<bool> Function(String content) onSendMessage;
  final VoidCallback onOpenPdf;

  const CollaborationChatbox({
    super.key,
    required this.roomId,
    required this.messages,
    required this.scrollController,
    required this.onSendMessage,
    required this.onOpenPdf,
  });

  @override
  State<CollaborationChatbox> createState() => _CollaborationChatboxState();
}

class _CollaborationChatboxState extends State<CollaborationChatbox> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Map<String, bool> _expandedMessages = {};
  bool _isSending = false;

  static const List<String> _suggestedMentions = [
    "@Orchestrator",
    "@Location Scout",
    "@Competitor Analyst",
    "@Business Planner",
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _insertMention(String mention) {
    final text = _inputController.text;
    final selection = _inputController.selection;
    
    String newText;
    int newCursorPos;
    
    if (selection.isValid) {
      newText = text.replaceRange(selection.start, selection.end, "$mention ");
      newCursorPos = selection.start + mention.length + 1;
    } else {
      newText = text.isEmpty ? "$mention " : "$text $mention ";
      newCursorPos = newText.length;
    }
    
    _inputController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
    _focusNode.requestFocus();
  }

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    final success = await widget.onSendMessage(text);
    if (success) {
      _inputController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to transmit message to mesh.")),
      );
    }

    setState(() {
      _isSending = false;
    });
  }

  List<InlineSpan> _parseMentions(String text, Color baseTextColor, bool isUser) {
    final List<InlineSpan> spans = [];
    final RegExp regex = RegExp(
      r'(@Orchestrator|@Location Scout|@Competitor Analyst|@Business Planner)',
    );
    final Iterable<RegExpMatch> matches = regex.allMatches(text);

    if (matches.isEmpty) {
      spans.add(TextSpan(text: text, style: TextStyle(color: baseTextColor)));
      return spans;
    }

    int start = 0;
    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: TextStyle(color: baseTextColor),
        ));
      }
      final mention = match.group(0)!;
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isUser
                ? Colors.white.withOpacity(0.12)
                : const Color(0xFFFF187F).withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isUser
                  ? Colors.white.withOpacity(0.3)
                  : const Color(0xFFFF187F).withOpacity(0.3),
              width: 0.8,
            ),
          ),
          child: Text(
            mention,
            style: GoogleFonts.outfit(
              color: isUser ? Colors.white : const Color(0xFFFF187F),
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ));
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: TextStyle(color: baseTextColor),
      ));
    }
    return spans;
  }

  Color _agentColor(String agent) {
    switch (agent) {
      case "Orchestrator":
        return const Color(0xFFFF187F);
      case "Location Scout":
        return const Color(0xFFC59F4A);
      case "Competitor Analyst":
        return const Color(0xFF111111);
      case "Business Planner":
        return const Color(0xFFECC870);
      default:
        return Colors.grey;
    }
  }

  IconData _agentIcon(String agent) {
    switch (agent) {
      case "Orchestrator":
        return Icons.settings_input_component_outlined;
      case "Location Scout":
        return Icons.map_outlined;
      case "Competitor Analyst":
        return Icons.analytics_outlined;
      case "Business Planner":
        return Icons.article_outlined;
      default:
        return Icons.smart_toy_outlined;
    }
  }

  String _agentRoleTag(String agent) {
    switch (agent) {
      case "Orchestrator":
        return "Coordinator";
      case "Location Scout":
        return "GIS + Bright Data";
      case "Competitor Analyst":
        return "Market Saturation";
      case "Business Planner":
        return "Strategy Architect";
      default:
        return "Agent";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Message Feed
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFECC870).withOpacity(0.3),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFECC870).withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: widget.messages.isEmpty
                ? const Center(
                    child: Text(
                      "Connecting to Band room event mesh...",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      final msg = widget.messages[index];
                      return _buildMessageRow(msg, index);
                    },
                  ),
          ),
        ),

        // Quick Mentions Rail
        Container(
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _suggestedMentions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final mention = _suggestedMentions[index];
              return ActionChip(
                backgroundColor: const Color(0xFFF1F5F9),
                side: BorderSide(
                  color: const Color(0xFFFF187F).withOpacity(0.15),
                  width: 1.0,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                label: Text(
                  mention,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF187F),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _insertMention(mention),
              );
            },
          ),
        ),

        // Input Field Bar
        Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  maxLines: null,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: "Mention agent to prompt research...",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _isSending ? null : _handleSend,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF187F),
                        Color(0xFFFF489F),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF187F).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageRow(RoomMessage msg, int index) {
    final isUser = msg.role == 'user' ||
        msg.sender.toLowerCase() == 'user' ||
        msg.sender.toLowerCase() == 'client';

    if (isUser) {
      final messageWidget = Container(
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B), // Slate Grey
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12.0,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
              children: _parseMentions(msg.content, Colors.white, true),
            ),
          ),
        ),
      );
      return AnimatedMessageBubble(child: messageWidget);
    }

    if (msg.role == 'system' || msg.type == 'status') {
      final isOrchestration = msg.type == "orchestration";
      final messageWidget = Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: isOrchestration
              ? const Color(0xFF111111)
              : const Color(0xFFF9F7F3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOrchestration
                ? const Color(0xFFFF187F).withOpacity(0.55)
                : const Color(0xFFECC870).withOpacity(0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isOrchestration
                  ? Icons.account_tree_outlined
                  : Icons.info_outline,
              color: isOrchestration
                  ? const Color(0xFFFF187F)
                  : const Color(0xFFECC870),
              size: 13,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isOrchestration ? "BAND_MESH: ${msg.content}" : msg.content,
                style: isOrchestration
                    ? GoogleFonts.sourceCodePro(
                        color: const Color(0xFF00D18F),
                        fontSize: 8.5,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      )
                    : TextStyle(
                        color: Colors.grey[800],
                        fontSize: 10.5,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
              ),
            ),
          ],
        ),
      );
      return AnimatedMessageBubble(child: messageWidget);
    }

    final agentColor = _agentColor(msg.sender);
    final roleTag = _agentRoleTag(msg.sender);
    final agentIcon = _agentIcon(msg.sender);
    final uniqueKey = "${widget.roomId}_message_$index";
    final isExpanded = _expandedMessages[uniqueKey] ?? false;
    final cleanContent = _messageContentForDisplay(msg);
    final preview = _messagePreview(cleanContent);
    final hasPdf =
        msg.sender == 'Business Planner' && msg.data.containsKey('pdf_url');

    final messageWidget = Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _expandedMessages[uniqueKey] = !isExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isExpanded
                  ? agentColor.withOpacity(0.65)
                  : const Color(0xFFECC870).withOpacity(0.25),
              width: isExpanded ? 1.2 : 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: agentColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: agentColor, width: 1.4),
                    ),
                    alignment: Alignment.center,
                    child: Icon(agentIcon, color: agentColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.sender,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: agentColor == Colors.black
                                ? Colors.black
                                : agentColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          roleTag,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (msg.data.containsKey('diagnostics')) ...[
                          const SizedBox(height: 4),
                          _buildDiagnosticsBadge(msg.data['diagnostics']),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F7F3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: agentColor.withOpacity(0.18)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isExpanded ? Icons.unfold_less : Icons.unfold_more,
                          color: agentColor,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isExpanded ? "OPEN" : "FOLDED",
                          style: TextStyle(
                            color: agentColor == Colors.black
                                ? Colors.black
                                : agentColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 180),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: TypewriterPlainText(
                  key: ValueKey("preview_${msg.id}"),
                  text: preview,
                  style: TextStyle(
                    color: Colors.grey[850],
                    fontSize: 10.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                ),
                secondChild: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFECC870).withOpacity(0.2),
                      width: 0.8,
                    ),
                  ),
                  child: TypewriterMarkdown(
                    key: ValueKey("full_${msg.id}"),
                    text: cleanContent,
                  ),
                ),
              ),
              if (hasPdf) ...[
                const SizedBox(height: 12),
                _buildInlinePdfCard(),
              ],
            ],
          ),
        ),
      ),
    );

    return AnimatedMessageBubble(child: messageWidget);
  }

  Widget _buildDiagnosticsBadge(Map<dynamic, dynamic> diag) {
    final provider = diag['provider'] ?? 'LLM';
    final model = diag['model'] ?? '';
    final latency = diag['latency_sec'];
    final latencyStr = latency != null ? "${latency}s" : "";
    final double? cost = diag['cost_usd'] != null
        ? double.tryParse(diag['cost_usd'].toString())
        : null;

    final isFeatherless =
        provider.toString().toLowerCase().contains('featherless');

    Color bgColor = const Color(0xFFF8FAFC);
    Color borderColor = const Color(0xFFE2E8F0);
    Color textColor = const Color(0xFF64748B);

    if (provider.toString().toLowerCase().contains('aimlapi') ||
        provider.toString().toLowerCase().contains('ai/ml')) {
      bgColor = const Color(0xFFFFF1F2);
      borderColor = const Color(0xFFFECDD3);
      textColor = const Color(0xFFE11D48);
    } else if (isFeatherless) {
      bgColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF15803D);
    }

    List<String> segments = [provider.toString(), model.toString()];
    if (latencyStr.isNotEmpty) {
      segments.add(latencyStr);
    }
    if (!isFeatherless && cost != null) {
      segments.add("\$${cost.toStringAsFixed(4)}");
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.memory_outlined,
            size: 8,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              segments.join(" | "),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.firaCode(
                color: textColor,
                fontSize: 7.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _messageContentForDisplay(RoomMessage msg) {
    return msg.content
        .split('\n')
        .where((line) {
          final lower = line.toLowerCase();
          return !lower.contains('download link') &&
              !lower.contains('/api/rooms/') &&
              !lower.contains('http://');
        })
        .join('\n')
        .trim();
  }

  String _messagePreview(String text) {
    final compact = text
        .replaceAll(RegExp(r'[#*_`>]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (compact.length <= 220) return compact;
    return "${compact.substring(0, 220).trim()}...";
  }

  Widget _buildInlinePdfCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFF187F).withOpacity(0.5),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_outlined,
            color: Color(0xFFFF187F),
            size: 24,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Business Plan PDF",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Saved locally when opened",
                  style: TextStyle(color: Colors.grey, fontSize: 8.5),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: widget.onOpenPdf,
            icon: const Icon(Icons.save_alt, size: 14, color: Colors.white),
            label: const Text(
              "Open",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF187F),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
