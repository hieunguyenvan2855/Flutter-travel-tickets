import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'booking_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = Provider.of<User?>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: FutureBuilder<UserModel?>(
        future: user != null ? authService.getUserData(user.uid) : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final userData = snapshot.data;
          final int bookingCount = userData?.bookingHistory.length ?? 0;

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue[900],
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      child: Column(
                        children: [
                          const CircleAvatar(radius: 55, backgroundColor: Colors.white, child: Icon(Icons.person, size: 70, color: Colors.blue)),
                          const SizedBox(height: 10),
                          Text(userData?.name ?? 'Khách hàng', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text(userData?.email ?? '', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 140),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildStatItem('Chuyến đi', bookingCount.toString(), Icons.map),
                      _buildStatItem('Điểm thưởng', (bookingCount * 100).toString(), Icons.stars),
                      _buildStatItem('Hạng', bookingCount > 5 ? 'Vàng' : 'Bạc', Icons.workspace_premium),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildMenuTile(Icons.history, 'Lịch sử chuyến đi', () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingHistoryScreen()));
                      }),
                      _buildMenuTile(Icons.logout, 'Đăng xuất', () => _showLogoutDialog(context, authService), color: Colors.red),
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.blue[900], size: 28),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.blue[900]),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
          TextButton(onPressed: () async { Navigator.pop(context); await authService.signOut(); }, child: const Text('Đăng xuất', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
