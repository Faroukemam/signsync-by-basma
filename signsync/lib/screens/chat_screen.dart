import 'package:flutter/material.dart';
import 'package:signsync/components/smartwidget.dart';

/// Thin screen wrapper around the WhatsApp-style chat widget.
///
/// Keeps navigation concerns in `screens/` while the reusable UI lives in
/// `components/`. This makes it easy to push the chat from anywhere without
/// duplicating setup code.
///
/// Quick usage:
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => const ChatScreen(title: 'John Doe', subtitle: 'online'),
/// ));
class ChatScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final ImageProvider? avatar;
  final List<ChatMessage>? initialMessages;
  final ValueChanged<String>? onSend;

  const ChatScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.avatar,
    this.initialMessages,
    this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    // Delegate to the reusable chat widget while passing through props.
    return WhatsAppChat(
      title: title,
      subtitle: subtitle,
      avatar: avatar,
      initialMessages: initialMessages,
      onSend: onSend,
    );
  }
}
