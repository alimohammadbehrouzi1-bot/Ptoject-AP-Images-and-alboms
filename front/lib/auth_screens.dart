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
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$').hasMatch(value)) {
      return 'Must include Uppercase, Lowercase and Digit';
    }
    return null;
  }

  Future<void> _login(bool isAdmin) async {
    final FormState? form = _formKey.currentState;
    if (form != null && form.validate()) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      if (isAdmin) {
        bool success = await DataService().loginAdmin(username, password);
        if (success && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else if (mounted) {
          _showError("Invalid Admin Credentials");
        }
      } else {
        final user = await DataService().loginUser(username, password);
        if (user != null && mounted) {
          if (user.containsKey('error') && user['error'] == 'BANNED') {
            _showError("Your account is BANNED!");
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MainNavigation(username: user['username']),
              ),
            );
          }
        } else if (mounted) {
          _showError("Invalid Username or Password");
        }
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
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
                  Icon(
                    Icons.photo_library_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Social Gallery',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Username',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _login(false),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _login(true),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Sign In as Admin'),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "New here? ",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                          ),
                        ),
                        child: Text(
                          "Create Account",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uC = TextEditingController();
  final _pC = TextEditingController();
  final _eC = TextEditingController();
  final _phC = TextEditingController();

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form != null && form.validate()) {
      if (_eC.text.isEmpty && _phC.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least Email or Phone is required')),
        );
        return;
      }
      final response = await DataService().registerUser(
        username: _uC.text.trim(),
        password: _pC.text.trim(),
        email: _eC.text.trim(),
        phone: _phC.text.trim(),
      );

      if (response.isSuccess) {
        // Auto-Login after registration
        await DataService().loginUser(_uC.text.trim(), _pC.text.trim());
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => MainNavigation(username: _uC.text.trim()),
            ),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Registration Failed')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _uC,
                decoration: const InputDecoration(
                  labelText: 'Username *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Username is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pC,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password *',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 8) return 'Minimum 8 characters';
                  if (!RegExp(
                    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$',
                  ).hasMatch(v))
                    return 'Must include Upper, Lower and Digit';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _eC,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (v) {
                  if (v != null &&
                      v.isNotEmpty &&
                      !RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
                    return 'Invalid Email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phC,
                decoration: const InputDecoration(
                  labelText: 'Phone (e.g. 989123456789)',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v != null &&
                      v.isNotEmpty &&
                      !RegExp(r'^98\d{10}$').hasMatch(v))
                    return 'Must be 12 digits starting with 98';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              const Text(
                '* At least Email or Phone is required',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _submit, child: const Text('Register')),
            ],
          ),
        ),
      ),
    );
  }
}
