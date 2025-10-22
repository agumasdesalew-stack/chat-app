import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

class MessageService {
  final supabase = Supabase.instance.client;
  final String currentUserId = Supabase.instance.client.auth.currentUser!.id;

  Future<List<MessageModel>> getMessages(String receiverId) async {
    final response = await supabase
        .from('messages')
        .select()
        .or(
          'and(sender_id.eq.$currentUserId,receiver_id.eq.$receiverId),'
          'and(sender_id.eq.$receiverId,receiver_id.eq.$currentUserId)'
        )
        .order('created_at', ascending: true);

    return (response as List).map((json) => MessageModel.fromJson(json)).toList();
  }

  Future<void> sendMessage(String receiverId, String content) async {
    await supabase.from('messages').insert({
      'sender_id': currentUserId,
      'receiver_id': receiverId,
      'content': content,
    });
  }

  Stream<List<MessageModel>> getMessagesStream(String receiverId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) {
          final messages = data.map((json) => MessageModel.fromJson(json)).toList();
          // Filter messages client-side for the specific chat
          return messages
              .where((msg) =>
                  (msg.senderId == currentUserId && msg.receiverId == receiverId) ||
                  (msg.senderId == receiverId && msg.receiverId == currentUserId))
              .toList();
        });
  }
}