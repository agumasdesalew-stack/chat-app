import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  final supabase = Supabase.instance.client;

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final response = await supabase.from('users').select().ilike('username', '%$query%');
    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }

  Future<List<UserModel>> getActiveUsers() async {
    final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String();
    final response = await supabase
        .from('users')
        .select()
        .gt('last_active', fiveMinAgo)
        .order('last_active', ascending: false)
        .limit(5);
    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }

  Stream<List<UserModel>> getActiveUsersStream() {
    final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String();
    return supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .gt('last_active', fiveMinAgo)
        .order('last_active', ascending: false)
        .limit(5)
        .map((data) => data.map((json) => UserModel.fromJson(json)).toList());
  }
}