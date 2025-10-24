import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';

class UserService {
  final supabase = Supabase.instance.client;
  final String currentUserId = Supabase.instance.client.auth.currentUser!.id;

  // Recent chats stream 
  Stream<List<Map<String, dynamic>>> getRecentChatsStream() {
    final controller = StreamController<List<Map<String, dynamic>>>();

    // Step 1: Initial load
    _fetchRecentChats(supabase).then(controller.add);

    // Step 2: Subscribe to realtime INSERT events on messages
    final channel = supabase.channel('public:messages')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        callback: (payload) async {
          final recentChats = await _fetchRecentChats(supabase);
          controller.add(recentChats);
        },
      )
      ..subscribe();

    // Step 3: Cleanup
    controller.onCancel = () {
      supabase.removeChannel(channel);
    };

    return controller.stream;
  }

  // Helper for recent chats
  Future<List<Map<String, dynamic>>> _fetchRecentChats(SupabaseClient supabase) async {
    final currentUserId = supabase.auth.currentUser!.id;

    final messages = await supabase
        .from('messages')
        .select('id, sender_id, receiver_id, created_at')
        .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
        .order('created_at', ascending: false)
        .limit(5);

    final uniqueIds = <String>{currentUserId};
    final recentChatIds = (messages as List)
        .map((msg) {
          final senderId = msg['sender_id'];
          final receiverId = msg['receiver_id'];
          final otherId = senderId == currentUserId ? receiverId : senderId;
          if (!uniqueIds.contains(otherId)) {
            uniqueIds.add(otherId);
            return otherId;
          }
          return null;
        })
        .whereType<String>()
        .toList();

    if (recentChatIds.isEmpty) return [];

    final users = await supabase
        .from('users')
        .select('id, username')
        .inFilter('id', recentChatIds);

    return (users as List)
        .map((u) => {
              'id': u['id'],
              'username': u['username'],
            })
        .toList();
  }

  // Active users stream 
  Stream<List<Map<String, dynamic>>> getActiveUsersStream() {
    final controller = StreamController<List<Map<String, dynamic>>>();

    // Step 1: Load initial active users
    _fetchActiveUsers(supabase).then(controller.add);

    // Step 2: Subscribe to realtime UPDATE events on users
    final channel = supabase.channel('public:users')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'users',
        callback: (payload) async {
          final users = await _fetchActiveUsers(supabase);
          controller.add(users);
        },
      )
      ..subscribe();

    // Step 3: Cleanup when stream closes
    controller.onCancel = () {
      supabase.removeChannel(channel);
    };

    return controller.stream;
  }

  // Helper for fetching active users
  Future<List<Map<String, dynamic>>> _fetchActiveUsers(SupabaseClient supabase) async {
    final now = DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String();

    final response = await supabase
        .from('users')
        .select('id, username, last_active')
        .gt('last_active', now)
        .neq('id', supabase.auth.currentUser!.id);

    return (response as List)
        .map((user) => {
              'id': user['id'],
              'username': user['username'],
            })
        .toList();
  }

  // Search users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await supabase
          .from('users')
          .select('id, username')
          .ilike('username', '%$query%')
          .neq('id', currentUserId);

      return (response as List).map((user) => {
            'id': user['id'],
            'username': user['username'],
          }).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}

// Helper class for message snapshots (optional)
class MessageSnapshot {
  final String senderId;
  final String receiverId;
  final DateTime createdAt;

  MessageSnapshot({
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
  });
}
