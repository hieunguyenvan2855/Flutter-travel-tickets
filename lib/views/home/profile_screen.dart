import 'package:cloud_firestore/cloud_firestore.dart'; // Đã thêm thư viện Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = Provider.of<User?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                // Phần Header (Giữ nguyên)
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
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        userData?.email ?? '',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Phần Menu các chức năng (Giữ nguyên, chỉ sửa đường dẫn onTap của nút đầu tiên)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildProfileItem(Icons.history, 'Lịch sử chuyến đi', () {
                        // Đã thêm lệnh chuyển hướng sang màn hình Lịch sử (Task 3.2)
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const BookingHistoryScreen()));
                      }),
                      _buildProfileItem(
                          Icons.favorite_border, 'Tour đã lưu', () {}),
                      _buildProfileItem(
                          Icons.settings, 'Cài đặt tài khoản', () {}),
                      _buildProfileItem(
                          Icons.help_outline, 'Hỗ trợ khách hàng', () {}),
                      const Divider(height: 40),
                      _buildProfileItem(Icons.logout, 'Đăng xuất',
                          () => _showLogoutDialog(context, authService),
                          color: Colors.red),
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

  Widget _buildProfileItem(IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
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
          content:
              const Text('Bạn có chắc chắn muốn thoát khỏi ứng dụng không?'),
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
              child:
                  const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

// =========================================================================
// TASK 3.2 & 3.3: MÀN HÌNH LỊCH SỬ ĐẶT VÉ (CÓ 2 TAB)
// =========================================================================
class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  // HÀM HIỂN THỊ POPUP ĐÁNH GIÁ (TASK 3.3)
  void _showReviewBottomSheet(BuildContext context, String tourId, String bookingDocId) {
    double ratingValue = 5.0;
    TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20, right: 20, top: 24
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Đánh giá chuyến đi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              RatingBar.builder(
                initialRating: 5, minRating: 1, direction: Axis.horizontal, allowHalfRating: true,
                itemCount: 5, itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) => ratingValue = rating,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: commentController, maxLines: 3,
                decoration: InputDecoration(
                    hintText: "Hãy chia sẻ trải nghiệm của bạn...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      // 1. Lưu đánh giá vào bảng reviews
                      await FirebaseFirestore.instance.collection('reviews').add({
                        'tourId': tourId,
                        'userId': user.uid,
                        'userName': user.displayName ?? user.email ?? "Khách hàng",
                        'rating': ratingValue,
                        'comment': commentController.text,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      // 2. Cập nhật trạng thái vé là đã đánh giá
                      await FirebaseFirestore.instance.collection('bookings').doc(bookingDocId).update({'isReviewed': true});

                      if (context.mounted) {
                        Navigator.pop(context); // Đóng popup
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!'), backgroundColor: Colors.green));
                      }
                    }
                  },
                  child: const Text("Gửi đánh giá", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // HÀM HỦY VÉ
  void _deleteBooking(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy vé'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn đặt vé này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Không')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('bookings').doc(docId).delete();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy vé thành công!'), backgroundColor: Colors.red));
            },
            child: const Text('Hủy vé', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vé của tôi'), backgroundColor: Colors.blue[900]),
        body: const Center(child: Text("Vui lòng đăng nhập để xem lịch sử")),
      );
    }

    return DefaultTabController(
      length: 2, // 2 Tab: Chưa thanh toán & Đã thanh toán
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Vé của tôi', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.orange,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Chưa thanh toán"),
              Tab(text: "Đã thanh toán"),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            // TÁCH DỮ LIỆU THÀNH 2 DANH SÁCH CHO 2 TAB
            final allBookings = snapshot.data!.docs;
            final pendingBookings = allBookings.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'pending').toList();
            final paidBookings = allBookings.where((doc) {
              final status = (doc.data() as Map<String, dynamic>)['status'];
              return status == 'paid' || status == 'completed';
            }).toList();

            return TabBarView(
              children: [
                _buildBookingList(context, pendingBookings, isPendingTab: true),
                _buildBookingList(context, paidBookings, isPendingTab: false),
              ],
            );
          },
        ),
      ),
    );
  }

  // WIDGET VẼ DANH SÁCH VÉ CHO TỪNG TAB
  Widget _buildBookingList(BuildContext context, List<QueryDocumentSnapshot> bookings, {required bool isPendingTab}) {
    if (bookings.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final data = bookings[index].data() as Map<String, dynamic>;
        final docId = bookings[index].id;
        final isReviewed = data['isReviewed'] ?? false;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(data['tourName'] ?? 'Tên Tour', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: isPendingTab ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(isPendingTab ? "Chờ thanh toán" : "Đã thanh toán", style: TextStyle(color: isPendingTab ? Colors.orange : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.confirmation_num_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Số vé: ${data['tickets']} vé'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Tổng: ${data['totalPrice']} VNĐ', style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold)),
                      ],
                    ),

                    // NÚT CHỨC NĂNG THEO TỪNG TAB
                    if (isPendingTab)
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _deleteBooking(context, docId),
                            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                            onPressed: () {
                              // Nhảy sang trang Thanh toán
                              Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentScreen(bookingData: data, docId: docId)));
                            },
                            child: const Text('Thanh toán', style: TextStyle(color: Colors.white, fontSize: 13)),
                          )
                        ],
                      )
                    else if (!isPendingTab && !isReviewed)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        onPressed: () => _showReviewBottomSheet(context, data['tourId'] ?? '', docId),
                        child: const Text('Đánh giá', style: TextStyle(color: Colors.white, fontSize: 13)),
                      )
                    else if (!isPendingTab && isReviewed)
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 14),
                            SizedBox(width: 4),
                            Text('Đã đánh giá', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Chưa có dữ liệu ở mục này.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// =========================================================================
// MÀN HÌNH THANH TOÁN ONLINE (MỚI THÊM)
// =========================================================================
class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final String docId;

  const PaymentScreen({super.key, required this.bookingData, required this.docId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'Tiền mặt';

  @override
  Widget build(BuildContext context) {
    final data = widget.bookingData;

    // Xử lý hiển thị ngày giờ đẹp mắt
    String bookingDate = "Chưa cập nhật";
    if (data['createdAt'] != null) {
      try {
        DateTime date = (data['createdAt'] as Timestamp).toDate();
        bookingDate = "${date.hour}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}/${date.year}";
      } catch(e) {
        bookingDate = "Lỗi hiển thị ngày";
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán vé', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chi tiết giao dịch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow('Tên Tour:', data['tourName'] ?? 'Chưa rõ'),
                    const Divider(),
                    _buildInfoRow('Ngày đặt:', bookingDate),
                    const Divider(),
                    _buildInfoRow('Số điện thoại:', data['phone'] ?? 'Chưa cung cấp'),
                    const Divider(),
                    _buildInfoRow('Email:', data['email'] ?? 'Chưa cung cấp'),
                    const Divider(),
                    _buildInfoRow('Số lượng vé:', '${data['tickets']} vé'),
                    const Divider(),
                    _buildInfoRow('Mã Voucher:', data['voucher'] ?? 'Không dùng'),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng cần thanh toán:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '${data['totalPrice']} VNĐ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Chọn phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  RadioListTile(
                    title: const Text('Thanh toán tiền mặt'),
                    subtitle: const Text('Thanh toán trực tiếp tại văn phòng'),
                    value: 'Tiền mặt',
                    groupValue: _selectedPaymentMethod,
                    activeColor: Colors.blue[900],
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val.toString()),
                  ),
                  RadioListTile(
                    title: const Text('Chuyển khoản ngân hàng'),
                    subtitle: const Text('Quét mã QR qua ứng dụng ngân hàng'),
                    value: 'Chuyển khoản',
                    groupValue: _selectedPaymentMethod,
                    activeColor: Colors.blue[900],
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val.toString()),
                  ),
                  RadioListTile(
                    title: const Text('Ví điện tử Momo / ZaloPay'),
                    value: 'Ví điện tử',
                    groupValue: _selectedPaymentMethod,
                    activeColor: Colors.blue[900],
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val.toString()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            // Lệnh cập nhật trạng thái đơn hàng lên Firebase thành 'paid'
            await FirebaseFirestore.instance.collection('bookings').doc(widget.docId).update({
              'status': 'paid',
              'paymentMethod': _selectedPaymentMethod,
              'paidAt': FieldValue.serverTimestamp(), // Lưu lại thời gian thanh toán
            });

            if (context.mounted) {
              Navigator.pop(context); // Quay về màn hình Lịch sử
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thanh toán thành công!'), backgroundColor: Colors.green),
              );
            }
          },
          child: const Text('XÁC NHẬN THANH TOÁN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
