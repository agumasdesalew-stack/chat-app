import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

class MessageTile extends StatelessWidget {
  final MessageModel message;
  final String receiverUsername;
  const MessageTile({super.key, required this.message, required this.receiverUsername});

  @override
  Widget build(BuildContext context) {
    final isMe = message.senderId == Supabase.instance.client.auth.currentUser!.id;
    return ListTile(
      title: Text(message.content),
      subtitle: Text(isMe ? 'You' : receiverUsername),
      trailing: Text(message.createdAt.toString().substring(11, 16)),
    );
  }
}