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
    try {
      // Perform signup
      final response = await supabase.auth.signUp(email: email, password: password);
      
      // Check if user was created successfully
      if (response.user == null) {
        throw Exception('Signup failed: No user created');
      }

      // Insert into users table
      await supabase.from('users').insert(UserModel(
        id: response.user!.id,
        firstName: firstName,
        secondName: secondName,
        username: username,
        email: email,
        lastActive: DateTime.now(),
      ).toJson());
    } catch (e) {
      // Rethrow the error with more context
      throw Exception('Signup failed: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
    // Trigger handles last_active update
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