/*
  WhatsApp-style Chat Widgets for SignSync

  Overview
  - Full chat screen (`WhatsAppChat`) with bubbles, timestamps, and delivery
    ticks that mimic WhatsApp’s layout and behavior.
  - Simple message model (`ChatMessage`) and status enum (`MessageStatus`).
  - Self‑contained: no extra packages beyond Flutter.

  Quick Start
  - Push directly:
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => const WhatsAppChat(title: 'Support', subtitle: 'online'),
      ));

  - Or via the screen wrapper at `lib/screens/chat_screen.dart`:
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => const ChatScreen(title: 'John Doe', subtitle: 'online'),
      ));

  Integration
  - Provide `initialMessages` to show history.
  - Use `onSend` to forward typed messages to your API/WebSocket.
  - To add remote replies, append to the `initialMessages` you hold in a parent
    widget and rebuild, or modify state here to inject messages.
*/
import 'package:flutter/material.dart';

/// Delivery/read state for messages (controls the tick icons).
enum MessageStatus { sending, sent, delivered, read }

/// Lightweight immutable message model used by the chat UI.
class ChatMessage {
  final String id;
  final String text;
  final DateTime time;
  final bool isMe;
  final MessageStatus status;
  const ChatMessage({
    required this.id,
    required this.text,
    required this.time,
    required this.isMe,
    this.status = MessageStatus.sent,
  });
  ChatMessage copyWith({
    String? id,
    String? text,
    DateTime? time,
    bool? isMe,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      time: time ?? this.time,
      isMe: isMe ?? this.isMe,
      status: status ?? this.status,
    );
  }
}

/// A reusable chat screen that mimics WhatsApp conversation layout.
///
/// Pass a `title` (contact name), optional `subtitle` (e.g. "online"),
/// an `avatar` image, and optionally `initialMessages`.
/// Hook `onSend` to integrate with your backend.
class WhatsAppChat extends StatefulWidget {
  final String title;
  final String? subtitle; // e.g. "online" or "last seen"
  final ImageProvider? avatar;
  final List<ChatMessage>? initialMessages;
  final ValueChanged<String>? onSend;
  const WhatsAppChat({
    super.key,
    required this.title,
    this.subtitle,
    this.avatar,
    this.initialMessages,
    this.onSend,
  });
  @override
  State<WhatsAppChat> createState() => _WhatsAppChatState();
}

class _WhatsAppChatState extends State<WhatsAppChat> {
  // Input controller for the composer text field.
  final TextEditingController _controller = TextEditingController();
  // Scroll controller for keeping the list pinned to the bottom.
  final ScrollController _scrollController = ScrollController();
  // Messages currently displayed (oldest → newest).
  late List<ChatMessage> _messages;
  @override
  void initState() {
    super.initState();
    _messages = widget.initialMessages ?? _seedMessages();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Reads current text, appends a message, and simulates status changes.
  void _sendCurrentText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      time: DateTime.now(),
      isMe: true,
      status: MessageStatus.sending,
    );
    setState(() {
      _messages = List.of(_messages)..add(msg);
    });
    _controller.clear();
    widget.onSend?.call(text);
    // Fake network delay: update status to sent/delivered/read
    Future.delayed(const Duration(milliseconds: 400), () {
      setState(() {
        _messages = _messages
            .map(
              (m) =>
                  m.id == msg.id ? m.copyWith(status: MessageStatus.sent) : m,
            )
            .toList();
      });
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      setState(() {
        _messages = _messages
            .map(
              (m) => m.id == msg.id
                  ? m.copyWith(status: MessageStatus.delivered)
                  : m,
            )
            .toList();
      });
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      setState(() {
        _messages = _messages
            .map(
              (m) =>
                  m.id == msg.id ? m.copyWith(status: MessageStatus.read) : m,
            )
            .toList();
      });
      _jumpToBottom();
    });
    _jumpToBottom();
  }

  /// Smoothly scroll to the latest item after adding messages.
  void _jumpToBottom() {
    if (!_scrollController.hasClients) return;
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 1,
        leadingWidth: 32,
        titleSpacing: 0,
        // Contact row with avatar, name, and call/menu actions.
        title: Row(
          children: [
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.avatar,
              child: widget.avatar == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFCFEAE8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
      ),
      // WhatsApp-like chat wallpaper color.
      backgroundColor: const Color(0xFFECE5DD),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              // Message list (oldest at top → newest at bottom).
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final m = _messages[index];
                  return MessageBubble(message: m);
                },
              ),
            ),
            // Bottom input area with emoji, attach, camera and mic/send.
            _Composer(
              controller: _controller,
              onAttach: () {},
              onCamera: () {},
              onSend: _sendCurrentText,
            ),
          ],
        ),
      ),
    );
  }

  /// Small built-in demo messages to showcase the UI when none provided.
  List<ChatMessage> _seedMessages() {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: '1',
        text: 'Hey! 👋',
        time: now.subtract(const Duration(minutes: 6)),
        isMe: false,
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '2',
        text: 'Hi, how’s it going?',
        time: now.subtract(const Duration(minutes: 5, seconds: 30)),
        isMe: true,
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '3',
        text: 'All good! Working on SignSync UI. You?',
        time: now.subtract(const Duration(minutes: 4)),
        isMe: false,
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '4',
        text:
            'Nice! I’m wiring a WhatsApp-style chat screen. Looks clean so far.',
        time: now.subtract(const Duration(minutes: 3, seconds: 20)),
        isMe: true,
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '5',
        text: 'Send a message to test the composer ↓',
        time: now.subtract(const Duration(minutes: 1, seconds: 40)),
        isMe: false,
        status: MessageStatus.read,
      ),
    ];
  }
}

/// Single message bubble with WhatsApp-like shape and tiny time + ticks.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const MessageBubble({super.key, required this.message});
  // Bubble background for the current user (WhatsApp light green).
  Color get _meColor => const Color(0xFFDCF8C6); // WhatsApp green bubble
  Color get _otherColor => Colors.white;
  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final bg = isMe ? _meColor : _otherColor;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    // Rounded corners with a "tail" by flattening the inner bottom corner.
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 0),
      bottomRight: Radius.circular(isMe ? 0 : 16),
    );
    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isMe ? 60 : 8,
        right: isMe ? 8 : 60,
      ),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  // Cap width so long messages look balanced.
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: radius,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 58),
                        child: Text(
                          message.text,
                          style: const TextStyle(fontSize: 16, height: 1.3),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: _TimeAndStatus(
                          time: message.time,
                          isMe: isMe,
                          status: message.status,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tiny timestamp with optional delivery/read ticks (shown on own messages).
class _TimeAndStatus extends StatelessWidget {
  final DateTime time;
  final bool isMe;
  final MessageStatus status;
  const _TimeAndStatus({
    required this.time,
    required this.isMe,
    required this.status,
  });
  @override
  Widget build(BuildContext context) {
    final t = TimeOfDay.fromDateTime(time);
    // Format similar to WhatsApp: 08:15 AM / 10:42 PM
    final timeText =
        '${t.hourOfPeriod.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
    IconData? icon;
    Color iconColor = Colors.black45;
    if (isMe) {
      switch (status) {
        case MessageStatus.sending:
          icon = Icons.access_time;
          iconColor = Colors.black38;
          break;
        case MessageStatus.sent:
          icon = Icons.done;
          break;
        case MessageStatus.delivered:
          icon = Icons.done_all;
          break;
        case MessageStatus.read:
          icon = Icons.done_all;
          iconColor = const Color(0xFF34B7F1); // Blue ticks for "read"
          break;
      }
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeText,
          style: const TextStyle(fontSize: 11, color: Colors.black45),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(icon, size: 16, color: iconColor),
        ],
      ],
    );
  }
}

/// Bottom input area with emoji, attach, camera and mic/send toggle.
class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onCamera;
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.onCamera,
  });
  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    return Container(
      color: const Color(0xFFECE5DD),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: onAttach,
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.grey),
                    onPressed: onCamera,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF25D366),
              elevation: 1,
              // WhatsApp behavior: mic when empty, send when there is text.
              onPressed: hasText ? onSend : () {},
              child: Icon(
                hasText ? Icons.send : Icons.mic,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
