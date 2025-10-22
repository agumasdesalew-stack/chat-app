import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<void> signUp({
    required String firstName,
    String? secondName,
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signUp(email: email, password: password);
    await supabase.from('users').insert(UserModel(
      id: response.user!.id,
      firstName: firstName,
      secondName: secondName,
      username: username,
      email: email,
      lastActive: DateTime.now(),
    ).toJson());
  }

  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
    await supabase.from('users').update({
      'last_active': DateTime.now().toIso8601String(),
    }).eq('id', supabase.auth.currentUser!.id);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<UserModel> getCurrentUser() async {
    final response = await supabase
        .from('users')
        .select()
        .eq('id', supabase.auth.currentUser!.id)
        .single();
    return UserModel.fromJson(response);
  }
}