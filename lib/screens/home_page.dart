import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/user_tile.dart';
import '../providers/auth_provider.dart';
import 'auth_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _userService = UserService();
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  Stream<List<UserModel>>? _activeUsersStream;

  @override
  void initState() {
    super.initState();
    _activeUsersStream = _userService.getActiveUsersStream();
  }

  Future<void> _searchUsers(String query) async {
    final results = await _userService.searchUsers(query);
    setState(() => _searchResults = results);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Home')),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text('${currentUser?.firstName ?? ''} ${currentUser?.secondName ?? ''}'),
              accountEmail: Text(currentUser?.email ?? ''),
              currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
            ),
            ListTile(title: const Text('Username'), subtitle: Text(currentUser?.username ?? '')),
            ListTile(title: const Text('Settings'), onTap: () => print('Settings tapped')),
            ListTile(
              title: const Text('Sign Out'),
              onTap: () async {
                await authProvider.signOut();
                if (mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthPage()));
                }
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(labelText: 'Search by Username', border: OutlineInputBorder()),
              onChanged: _searchUsers,
            ),
          ),
          if (_searchResults.isNotEmpty) ...[
            const Text('Search Results:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._searchResults.map((user) => UserTile(user: user)),
          ],
          const SizedBox(height: 20),
          const Text('Active Users:', style: TextStyle(fontWeight: FontWeight.bold)),
          StreamBuilder<List<UserModel>>(
            stream: _activeUsersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return const Text('Error loading active users');
              }
              final activeUsers = snapshot.data ?? [];
              return Column(
                children: activeUsers.map((user) => UserTile(user: user)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}