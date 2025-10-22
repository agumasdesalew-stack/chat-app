import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../screens/chat_screen.dart';

class UserTile extends StatelessWidget {
  final UserModel user;
  const UserTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(user.username),
      subtitle: Text('${user.firstName} ${user.secondName ?? ''}'),
      trailing: Text(user.lastActive.toString().substring(11, 16)),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            receiverId: user.id,
            receiverUsername: user.username,
          ),
        ),
      ),
    );
  }
}