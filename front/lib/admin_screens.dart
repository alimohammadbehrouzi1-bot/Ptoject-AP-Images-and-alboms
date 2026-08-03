import 'package:flutter/material.dart';
import 'data_service.dart';
import 'auth_screens.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _handleBanToggle(String username) {
    setState(() {
      DataService().toggleBan(username);
    });
  }

  @override
  Widget build(BuildContext context) {
    final allUsers = DataService().rawUsers;
    final bannedUsers = allUsers.where((u) => u['isBanned'] == true).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Admin Console',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Users'),
            Tab(text: 'Banned'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => _showAdminSheet(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildUserList(allUsers), _buildUserList(bannedUsers)],
      ),
    );
  }

  Widget _buildUserList(List<dynamic> users) {
    if (users.isEmpty)
      return const Center(
        child: Text('No users found', style: TextStyle(color: Colors.grey)),
      );
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, i) {
        final u = users[i];
        bool isB = u['isBanned'] ?? false;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isB
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.blue.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: isB ? Colors.red : Colors.blue),
            ),
            title: Text(
              u['username'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Switch(
              value: !isB,
              onChanged: (v) => _handleBanToggle(u['username']),
            ),
            onTap: () => _showUserDetail(u),
          ),
        );
      },
    );
  }

  void _showUserDetail(Map<String, dynamic> u) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'User Info',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _row('Username', u['username']),
            _row('Email', u['email']),
            _row('Phone', u['phone']),
            _row('Status', u['isBanned'] ? 'Banned' : 'Active'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: Colors.grey)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  void _showAdminSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.shield, size: 40)),
            const SizedBox(height: 16),
            const Text(
              'Admin Account',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Change Admin Password'),
              onTap: () {
                Navigator.pop(context);
                _showChangePass();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                DataService().logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePass() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Old Password')),
            TextField(decoration: InputDecoration(labelText: 'New Password')),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
