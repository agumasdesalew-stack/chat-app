import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_service.dart';
import '../screens/chat_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _userService = UserService();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_searchUsers);
  }

  void _searchUsers() async {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      final users = await _userService.searchUsers(query);
      setState(() => _users = users);
    } else {
      setState(() => _users = []);
    }
  }

  void _navigateToChat(String receiverId, String receiverUsername) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(receiverId: receiverId, receiverUsername: receiverUsername),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login'); // Adjust route as needed
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  void _navigateToSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings page not implemented yet')),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final username = user?.userMetadata?['username'] ?? user?.email ?? 'User';
    final currentUserId = user?.id ?? '';

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Chats',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.teal,
          elevation: 4.0,
          actions: [
            
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  username,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.teal[200],
                  child: Text(
                    username[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                decoration: const BoxDecoration(
                  color: Colors.teal,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.teal),
                title: const Text('Settings'),
                onTap: _navigateToSettings,
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.teal),
                title: const Text('Logout'),
                onTap: _logout,
              ),
            ],
          ),
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search users...',
                    prefixIcon: const Icon(Icons.search, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Recent Chats',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _userService.getRecentChatsStream().asyncMap((future) => future),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.teal));
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      print('Recent chats error: ${snapshot.error}');
                      return const Center(child: Text('Error loading recent chats', style: TextStyle(color: Colors.red)));
                    }
                    final recentChats = snapshot.data!;
                    return ListView.builder(
                      itemCount: recentChats.length,
                      itemBuilder: (context, index) {
                        final chat = recentChats[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(
                                chat['username'][0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              chat['username'],
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: const Text('Last chatted', style: TextStyle(color: Color.fromARGB(255, 128, 124, 124))),
                            onTap: () => _navigateToChat(chat['id'], chat['username']),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Active Users',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _userService.getActiveUsersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.teal));
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      print('Active users error: ${snapshot.error}');
                      return const Center(child: Text('Error loading users', style: TextStyle(color: Colors.red)));
                    }
                    final activeUsers = snapshot.data!;
                    final displayUsers = _searchController.text.isEmpty ? activeUsers : _users;
                    return ListView.builder(
                      itemCount: displayUsers.length,
                      itemBuilder: (context, index) {
                        final user = displayUsers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(
                                user['username'][0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              user['username'],
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: const Text('Active now', style: TextStyle(color: Color.fromARGB(255, 136, 119, 119))),
                            onTap: () => _navigateToChat(user['id'], user['username']),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}