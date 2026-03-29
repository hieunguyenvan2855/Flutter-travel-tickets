import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = Provider.of<User?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<UserModel?>(
        future: user != null ? authService.getUserData(user.uid) : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final userData = snapshot.data;

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue[900],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 60, color: Colors.blue),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        userData?.name ?? 'Khách hàng',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        userData?.email ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildProfileItem(Icons.history, 'Lịch sử chuyến đi', () {}),
                      _buildProfileItem(Icons.favorite_border, 'Tour đã lưu', () {}),
                      _buildProfileItem(Icons.settings, 'Cài đặt tài khoản', () {}),
                      _buildProfileItem(Icons.help_outline, 'Hỗ trợ khách hàng', () {}),
                      const Divider(height: 40),
                      _buildProfileItem(
                        Icons.logout, 
                        'Đăng xuất', 
                        () => _showLogoutDialog(context, authService),
                        color: Colors.red
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.blue[900]),
      title: Text(title, style: TextStyle(fontSize: 16, color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn thoát khỏi ứng dụng không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authService.signOut();
              },
              child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
