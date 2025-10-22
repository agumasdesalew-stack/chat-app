import 'package:flutter/material.dart';
import '../services/message_service.dart';
import '../models/message_model.dart';
import '../widgets/message_tile.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverUsername;
  const ChatScreen({super.key, required this.receiverId, required this.receiverUsername});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageService = MessageService();
  final _messageController = TextEditingController();
  Stream<List<MessageModel>>? _messagesStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = _messageService.getMessagesStream(widget.receiverId);
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;
    await _messageService.sendMessage(widget.receiverId, _messageController.text);
    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.receiverUsername}')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return const Text('Error loading messages');
                }
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) => MessageTile(
                    message: messages[index],
                    receiverUsername: widget.receiverUsername,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(labelText: 'Type a message', border: OutlineInputBorder()),
                  ),
                ),
                IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}