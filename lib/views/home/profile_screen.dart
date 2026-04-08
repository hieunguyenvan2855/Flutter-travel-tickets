import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'booking_history_screen.dart';
import '../admin/admin_booking_screen.dart';
import '../admin/revenue_screen.dart';
import 'loyalty_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // HÀM HIỂN THỊ DIALOG ĐỔI MẬT KHẨU
  void _showChangePasswordDialog(BuildContext context, AuthService authService) {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPassController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: newPassController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu mới', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: confirmPassController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
              onPressed: isLoading ? null : () async {
                if (newPassController.text != confirmPassController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu xác nhận không khớp")));
                  return;
                }
                if (newPassController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu mới phải từ 6 ký tự")));
                  return;
                }

                setDialogState(() => isLoading = true);
                final error = await authService.changePassword(oldPassController.text, newPassController.text);
                setDialogState(() => isLoading = false);

                if (error == null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đổi mật khẩu thành công!"), backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                }
              },
              child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = Provider.of<User?>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Trung tâm quản lý', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
          final isAdmin = userData?.role == 'admin';
          final int bookingCount = userData?.bookingHistory.length ?? 0;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(userData),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
                  child: Row(
                    children: [
                      _buildStatItem(context, 'Chuyến đi', bookingCount.toString(), Icons.map_outlined, userData),
                      _buildStatItem(context, 'Điểm tích lũy', (userData?.points ?? 0).toString(), Icons.stars_outlined, userData),
                      _buildStatItem(context, 'Hạng', isAdmin ? 'QUẢN TRỊ' : (userData?.rank ?? 'BẠC'), Icons.verified_user_outlined, userData),
                    ],
                  ),
                ),

                if (isAdmin) ...[
                  _buildSectionTitle('QUẢN TRỊ HỆ THỐNG'),
                  _buildMenuContainer([
                    _buildMenuTile(Icons.admin_panel_settings, 'Quản lý Đơn hàng', 'Duyệt vé toàn hệ thống', () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminBookingScreen()));
                    }),
                    _buildMenuTile(Icons.analytics_outlined, 'Thống kê Doanh thu', 'Biểu đồ lợi nhuận theo tháng', () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminRevenueScreen()));
                    }),
                  ]),
                ],

                _buildSectionTitle('CÁ NHÂN & TIỆN ÍCH'),
                _buildMenuContainer([
                  _buildMenuTile(Icons.history, 'Lịch sử chuyến đi', 'Các tour bạn đã đặt và thanh toán', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingHistoryScreen()));
                  }),
                  _buildMenuTile(Icons.notifications_none, 'Thông báo', 'Cập nhật khuyến mãi mới nhất', () {}),
                  _buildMenuTile(Icons.lock_outline, 'Bảo mật tài khoản', 'Đổi mật khẩu', () {
                    _showChangePasswordDialog(context, authService);
                  }),
                ]),

                const SizedBox(height: 30),
                _buildLogoutButton(context, authService),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(UserModel? userData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
            child: const CircleAvatar(radius: 50, backgroundColor: Colors.white, child: Icon(Icons.person, size: 60, color: Colors.blue)),
          ),
          const SizedBox(height: 15),
          Text(userData?.name ?? 'Người dùng', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(userData?.email ?? '', style: const TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue[900], letterSpacing: 1.2)),
    );
  }

  Widget _buildMenuContainer(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(children: children),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, UserModel? userData) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (userData != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => LoyaltyScreen(userData: userData)));
          }
        },
        child: Column(
          children: [
            Icon(icon, color: Colors.blue[900], size: 26),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.blue[900], size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService authService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () => _showLogoutDialog(context, authService),
        child: const Text('Đăng xuất tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn thoát hệ thống không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(onPressed: () async { Navigator.pop(context); await authService.signOut(); }, child: const Text('Đăng xuất', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
