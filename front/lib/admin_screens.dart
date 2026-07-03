import 'package:flutter/material.dart';
import 'auth_screens.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Mock data representing Admin.allUsers
  final List<Map<String, dynamic>> _mockUsers = [
    {'username': 'User_1', 'email': 'u1@gmail.com', 'phone': '989123456781', 'isBanned': false, 'images': 12, 'albums': 2},
    {'username': 'User_2', 'email': 'u2@gmail.com', 'phone': '989123456782', 'isBanned': true, 'images': 5, 'albums': 1},
    {'username': 'User_3', 'email': 'u3@gmail.com', 'phone': '989123456783', 'isBanned': false, 'images': 20, 'albums': 4},
    {'username': 'User_4', 'email': 'u4@gmail.com', 'phone': '989123456784', 'isBanned': false, 'images': 0, 'albums': 0},
    {'username': 'User_5', 'email': 'u5@gmail.com', 'phone': '989123456785', 'isBanned': true, 'images': 8, 'albums': 2},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _handleBanToggle(int index, bool value) {
    setState(() {
      _mockUsers[index]['isBanned'] = !value; // Switch value is 'isActive'
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Admin Console', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1A73E8),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1A73E8),
          tabs: const [
            Tab(text: 'All Users'), // Matches printAllUsers()
            Tab(text: 'Banned'),    // Matches printAllBannedUsers()
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF1A73E8)),
            onPressed: () => _showAdminProfile(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(_mockUsers),
          _buildUserList(_mockUsers.where((u) => u['isBanned']).toList()),
        ],
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return const Center(child: Text('No users to display', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) => _buildUserCard(users[index]),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    bool isBanned = user['isBanned'];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: isBanned ? Colors.red[50] : Colors.blue[50],
          child: Icon(Icons.person, color: isBanned ? Colors.redAccent : const Color(0xFF1A73E8)),
        ),
        title: Text(user['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('ID: ${user['username'].hashCode.abs().toString().substring(0, 5)}'),
        trailing: Switch(
          value: !isBanned, // Matches banOrUnbanUser()
          activeThumbColor: const Color(0xFF1A73E8),
          onChanged: (v) {
            int mainIndex = _mockUsers.indexWhere((u) => u['username'] == user['username']);
            _handleBanToggle(mainIndex, v);
          },
        ),
        onTap: () => _showUserDetail(context, user), // Matches printUserInfo()
      ),
    );
  }

  void _showUserDetail(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('User Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _infoRow('Username', user['username']),
            _infoRow('Email', user['email']),
            _infoRow('Phone', user['phone']),
            _infoRow('Total Images', user['images'].toString()),
            _infoRow('Total Albums', user['albums'].toString()),
            _infoRow('Status', user['isBanned'] ? 'Banned' : 'Active'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black87),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdminProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.shield, size: 40)),
            const SizedBox(height: 16),
            const Text('Admin Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.password_rounded),
              title: const Text('Change Admin Password'), // Matches ChangePassword()
              onTap: () { Navigator.pop(context); _showChangePasswordDialog(); },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController oldC = TextEditingController();
    final TextEditingController newC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldC, decoration: const InputDecoration(labelText: 'Old Password'), obscureText: true),
            const SizedBox(height: 16),
            TextField(controller: newC, decoration: const InputDecoration(labelText: 'New Password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Update')),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
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
