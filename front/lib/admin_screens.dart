import 'package:flutter/material.dart';
import 'auth_screens.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            ),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, i) => _buildUserCard(context, i),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, int i) {
    bool isBanned = i % 4 == 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isBanned ? Colors.red[50] : Colors.blue[50],
            child: Icon(Icons.person, color: isBanned ? Colors.redAccent : const Color(0xFF1A73E8)),
          ),
          title: Text('User Account $i', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Images: ${i * 3} | Albums: $i'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(isBanned ? 'Banned' : 'Active', 
                   style: TextStyle(color: isBanned ? Colors.redAccent : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 30,
                child: Switch(
                  value: !isBanned,
                  activeThumbColor: const Color(0xFF1A73E8),
                  onChanged: (v) {},
                ),
              ),
            ],
          ),
          onTap: () => _showUserDetails(context, i),
        ),
      ),
    );
  }

  void _showUserDetails(BuildContext context, int i) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('User Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _detailRow('Username', 'User_$i'),
            _detailRow('Email', 'user$i@gmail.com'),
            _detailRow('Phone', '+98 912 345 678$i'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
