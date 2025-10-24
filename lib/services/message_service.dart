import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

class MessageService {
  final supabase = Supabase.instance.client;
  final String currentUserId = Supabase.instance.client.auth.currentUser!.id;

  Future<List<MessageModel>> getMessages(String receiverId) async {
    try {
      final response = await supabase
          .from('messages')
          .select()
          .or(
            'and(sender_id.eq.$currentUserId,receiver_id.eq.$receiverId),'
            'and(sender_id.eq.$receiverId,receiver_id.eq.$currentUserId)'
          )
          .order('created_at', ascending: true);

      return (response as List).map((json) => MessageModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching messages: $e');
      rethrow;
    }
  }

  Future<void> sendMessage(String receiverId, String content) async {
    try {
      await supabase.from('messages').insert({
        'sender_id': currentUserId,
        'receiver_id': receiverId,
        'content': content,
      });
      print('Message inserted into database');
    } catch (e) {
      print('Error inserting message: $e');
      rethrow;
    }
  }

  Stream<List<MessageModel>> getMessagesStream(String receiverId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) {
          print('Stream received ${data.length} messages');
          final messages = data.map((json) => MessageModel.fromJson(json)).toList();
          return messages
              .where((msg) =>
                  (msg.senderId == currentUserId && msg.receiverId == receiverId) ||
                  (msg.senderId == receiverId && msg.receiverId == currentUserId))
              .toList();
        });
  }

  Future<void> markMessagesAsRead(String senderId) async {
    try {
      await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('receiver_id', currentUserId)
          .eq('sender_id', senderId)
          .eq('is_read', false);
      print('Messages marked as read for sender: $senderId');
    } catch (e) {
      print('Error marking messages as read: $e');
      rethrow;
    }
  }
}