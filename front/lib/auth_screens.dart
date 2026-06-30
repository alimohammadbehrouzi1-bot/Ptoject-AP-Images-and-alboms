import 'package:flutter/material.dart';
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
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$').hasMatch(value)) {
      return 'Must include Uppercase, Lowercase and Digit';
    }
    return null;
  }

  void _login(bool isAdmin) {
    if (_formKey.currentState!.validate()) {
      if (isAdmin) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
      } else {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => MainNavigation(username: _usernameController.text))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, size: 64, color: Color(0xFF1A73E8)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1A73E8))),
                  const SizedBox(height: 8),
                  const Text('Manage and share your moments', style: TextStyle(color: Colors.black45)),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      hintText: 'Username',
                      prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF1A73E8)),
                    ),
                    validator: (v) => v!.isEmpty ? 'Please enter your username' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: Color(0xFF1A73E8)),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _login(false),
                    child: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _login(true),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: Colors.blue[200]!),
                    ),
                    child: const Text('Sign In as Admin', style: TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("New here? ", style: TextStyle(color: Colors.black45)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                        child: const Text("Create Account", style: TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.bold)),
                      ),
                    ],
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text('Join the Community', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            const TextField(decoration: InputDecoration(hintText: 'Username', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(hintText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 16),
            const TextField(obscureText: true, decoration: InputDecoration(hintText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
