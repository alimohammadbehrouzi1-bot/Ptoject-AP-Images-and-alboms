import 'package:flutter/material.dart';
import 'auth_screens.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: 8,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, i) => Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('User Account $i'),
            subtitle: Text('Images: ${i * 3} | Albums: $i'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Ban User'),
                Switch(
                  value: i % 4 == 0,
                  activeColor: Colors.red,
                  onChanged: (v) {},
                ),
              ],
            ),
            onTap: () {
              // Show more info
            },
          ),
        ),
      ),
    );
  }
}
