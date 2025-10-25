import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/message_service.dart';
import '../models/message_model.dart';
import '../widgets/message_tile.dart';
import '../services/user_service.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverUsername;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverUsername,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageService = MessageService();
  final _userService = UserService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Stream<List<MessageModel>>? _messagesStream;
  List<MessageModel> _localMessages = [];
  bool _hasError = false;
  bool _newMessageReceived = false;

  @override
  void initState() {
    super.initState();
    _messagesStream = _messageService.getMessagesStream(widget.receiverId);
    _markMessagesAsRead();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    final supabase = Supabase.instance.client;

    final channel = supabase.channel('public:messages')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'receiver_id',
          value: supabase.auth.currentUser!.id,
        ),
        callback: (payload) {
          final record = payload.newRecord as Map<String, dynamic>?;
          if (record != null && record['receiver_id'] == supabase.auth.currentUser!.id &&
              record['sender_id'] != widget.receiverId) {
            setState(() => _newMessageReceived = true);
            _showNotification();
          }
        },
      )
      ..subscribe((status, [error]) {
        if (status == 'SUBSCRIBED') {
          print('Realtime subscription successful');
        } else if (error != null) {
          print('Realtime subscription error: $error');
        }
      });
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await _messageService.markMessagesAsRead(widget.receiverId);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final optimisticMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      senderId: Supabase.instance.client.auth.currentUser!.id,
      receiverId: widget.receiverId,
      content: content,
      createdAt: DateTime.now(),
      isRead: false,
    );

    setState(() {
      _localMessages.add(optimisticMessage);
      _hasError = false;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      await _messageService.sendMessage(widget.receiverId, content);
      print('Message sent successfully');
    } catch (e) {
      print('Error sending message: $e');
      setState(() {
        _localMessages.remove(optimisticMessage);
        _hasError = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showNotification() {
    if (!_newMessageReceived) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('New message received!'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            setState(() => _newMessageReceived = false);
            // Implement navigation logic here
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(Supabase.instance.client.channel('public:messages'));
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            ' ${widget.receiverUsername}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.teal,
          elevation: 4.0,
          actions: [
            if (_newMessageReceived)
              IconButton(
                icon: const Icon(Icons.notification_important, color: Colors.white),
                onPressed: () => _showNotification(),
              ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal[100]!, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Row of recent contacts
              const Padding(
                padding: EdgeInsets.all(8.0),
                
              ),
              SizedBox(
                height: 80,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _userService.getRecentChatsStream().asyncMap((future) => future),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.teal));
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      print('Recent chats error: ${snapshot.error}');
                      return const SizedBox.shrink();
                    }
                    final recentChats = snapshot.data!;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recentChats.length,
                      itemBuilder: (context, index) {
                        final chat = recentChats[index];
                        final isActive = chat['id'] == widget.receiverId;
                        return GestureDetector(
                          onTap: isActive
                              ? null
                              : () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        receiverId: chat['id'],
                                        receiverUsername: chat['username'],
                                      ),
                                    ),
                                  );
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Card(
                              elevation: 2.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.teal));
                    }
                    if (snapshot.hasError) {
                      print('Stream error: ${snapshot.error}');
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Error loading messages', style: TextStyle(color: Colors.red)),
                            TextButton(
                              onPressed: () => setState(() {
                                _messagesStream = _messageService.getMessagesStream(widget.receiverId);
                              }),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    final serverMessages = snapshot.data ?? [];
                    final allMessages = [
                      ...serverMessages,
                      ..._localMessages.where((m) => !serverMessages.any((sm) => sm.id == m.id)),
                    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

                    if (allMessages.isEmpty) {
                      return const Center(child: Text('No messages yet', style: TextStyle(color: Color.fromARGB(255, 109, 103, 103))));
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      itemCount: allMessages.length,
                      itemBuilder: (context, index) {
                        final message = allMessages[index];
                        return MessageTile(
                          message: message,
                          receiverUsername: widget.receiverUsername,
                          key: ValueKey(message.id),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_hasError)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Error sending message', style: TextStyle(color: Colors.red)),
                ),
              Container(
                padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + keyboardHeight),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          prefixIcon: const Icon(Icons.message, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal,
                      ),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send, color: Colors.white),
                        padding: const EdgeInsets.all(10),
                        splashRadius: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}