import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _secondNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignup = true;
  String? _error;

  Future<void> _authAction() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      setState(() => _error = null);
      if (_isSignup) {
        await authProvider.signUp(
          firstName: _firstNameController.text,
          secondName: _secondNameController.text.isEmpty ? null : _secondNameController.text,
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await authProvider.signIn(_emailController.text, _passwordController.text);
      }
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignup ? 'Signup' : 'Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_isSignup) ...[
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _secondNameController,
                  decoration: const InputDecoration(labelText: 'Second Name (Optional)'),
                ),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username (Unique)'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
              ],
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _authAction,
                child: Text(_isSignup ? 'Signup' : 'Login'),
              ),
              TextButton(
                onPressed: () => setState(() => _isSignup = !_isSignup),
                child: Text(_isSignup ? 'Switch to Login' : 'Switch to Signup'),
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}