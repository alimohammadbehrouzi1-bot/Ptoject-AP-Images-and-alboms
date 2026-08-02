import 'package:flutter/material.dart';
import 'data_service.dart';
import 'user_screens.dart';
import 'admin_screens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Minimum 8 characters';
    return null;
  }

  // FIXED: Added async to handle Future from DataService
  Future<void> _login(bool isAdmin) async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      if (isAdmin) {
        // FIXED: Added await to ensure persistence is saved
        bool success = await DataService().loginAdmin(username, password);
        if (success && mounted) {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => const AdminDashboard())
          );
        } else if (mounted) {
          _showError("Invalid Admin Credentials");
        }
      } else {
        // FIXED: Added await to ensure persistence is saved
        final user = await DataService().loginUser(username, password);
        if (user != null && mounted) {
          if (user.containsKey('error') && user['error'] == 'BANNED') {
            _showError("Your account is BANNED!");
          } else {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => MainNavigation(username: user['username']))
            );
          }
        } else if (mounted) {
          if (DataService().rawUsers.isEmpty) {
            _showError("Database not loaded. Please restart.");
          } else {
            _showError("Wrong Username or Password");
          }
        }
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark ? Colors.blueGrey[900]! : Colors.blue[50]!,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 24),
                  Text('Social Gallery', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Username',
                      prefixIcon: Icon(Icons.person_outline_rounded, color: Theme.of(context).colorScheme.primary),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: Theme.of(context).colorScheme.primary),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _login(false),
                    child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _login(true),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Sign In as Admin'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: const Center(child: Text('Register using the mock users: ali, reza, sara')),
    );
  }
}
