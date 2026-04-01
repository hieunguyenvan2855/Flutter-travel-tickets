import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
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
        title: const Text('Hồ sơ cá nhân', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<UserModel?>(
        future: user != null ? authService.getUserData(user.uid) : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
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
                        userData?.name ?? user?.email?.split('@')[0] ?? 'Khách hàng',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(userData?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildProfileItem(Icons.history, 'Vé của tôi', () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingHistoryScreen()));
                      }),
                      _buildProfileItem(Icons.favorite_border, 'Tour đã lưu', () {}),
                      _buildProfileItem(Icons.settings, 'Cài đặt tài khoản', () {}),
                      const Divider(height: 40),
                      _buildProfileItem(Icons.logout, 'Đăng xuất', () => authService.signOut(), color: Colors.red),
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
}

// =========================================================================
// TASK 3.2 & 3.3: MÀN HÌNH LỊCH SỬ ĐẶT VÉ (CÓ CỘNG TRỪ SỐ VÉ)
// =========================================================================
class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  // HÀM MỚI: XỬ LÝ NÚT CỘNG/TRỪ SỐ LƯỢNG VÉ TRỰC TIẾP TRÊN FIREBASE
  Future<void> _updateTicketCount(String docId, int currentTickets, num currentTotal, int change) async {
    int newTickets = currentTickets + change;

    // Bắt lỗi: Không cho phép giảm xuống dưới 1 vé
    if (newTickets < 1) return;

    // Tính ra giá gốc của 1 vé, sau đó nhân với số vé mới
    double unitPrice = currentTotal / currentTickets;
    double newTotal = unitPrice * newTickets;

    // Lệnh Update thẳng lên Firebase. StreamBuilder sẽ tự động làm mới giao diện!
    await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
      'tickets': newTickets,
      'totalPrice': newTotal,
    });
  }

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
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 30, left: 20, right: 20, top: 24),
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
                decoration: InputDecoration(hintText: "Hãy chia sẻ trải nghiệm của bạn...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance.collection('reviews').add({
                        'tourId': tourId, 'userId': user.uid, 'userName': user.displayName ?? user.email ?? "Khách hàng",
                        'rating': ratingValue, 'comment': commentController.text, 'createdAt': FieldValue.serverTimestamp(),
                      });
                      await FirebaseFirestore.instance.collection('bookings').doc(bookingDocId).update({'isReviewed': true});
                      if (context.mounted) {
                        Navigator.pop(context);
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
      length: 2,
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
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

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

                // --- ĐOẠN ĐƯỢC NÂNG CẤP: GIAO DIỆN CỘNG TRỪ SỐ VÉ ---
                Row(
                  children: [
                    const Icon(Icons.confirmation_num_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Số vé: '),
                    // Nếu ở tab "Chưa thanh toán", hiện nút cộng trừ
                    if (isPendingTab) ...[
                      IconButton(
                        padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => _updateTicketCount(docId, data['tickets'], data['totalPrice'], -1),
                      ),
                      const SizedBox(width: 8),
                      Text('${data['tickets']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                        onPressed: () => _updateTicketCount(docId, data['tickets'], data['totalPrice'], 1),
                      ),
                    ]
                    // Nếu ở tab "Đã thanh toán", chỉ hiện chữ tĩnh
                    else ...[
                      Text('${data['tickets']} vé', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
                // ----------------------------------------------------

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
// MÀN HÌNH THANH TOÁN ONLINE (ĐÃ NÂNG CẤP FORM VÀ NGÂN HÀNG)
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

  // Các biến để hứng dữ liệu người dùng nhập vào
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Tự động điền sẵn nếu lúc đặt vé đã có sdt/email trên Firebase
    _phoneController.text = widget.bookingData['phone'] ?? '';
    _emailController.text = widget.bookingData['email'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.bookingData;

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
            // =====================================================
            // 1. FORM ĐIỀN THÔNG TIN KHÁCH HÀNG
            // =====================================================
            const Text('Thông tin người đặt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email liên hệ',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // =====================================================
            // 2. CHI TIẾT GIAO DỊCH
            // =====================================================
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
                    _buildInfoRow('Số lượng vé:', '${data['tickets']} vé'),
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

            // =====================================================
            // 3. PHƯƠNG THỨC THANH TOÁN
            // =====================================================
            const Text('Chọn phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  RadioListTile(
                    title: const Text('Thanh toán tiền mặt'),
                    value: 'Tiền mặt',
                    groupValue: _selectedPaymentMethod,
                    activeColor: Colors.blue[900],
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val.toString()),
                  ),
                  RadioListTile(
                    title: const Text('Chuyển khoản ngân hàng'),
                    value: 'Chuyển khoản',
                    groupValue: _selectedPaymentMethod,
                    activeColor: Colors.blue[900],
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val.toString()),
                  ),
                ],
              ),
            ),

            // =====================================================
            // 4. HIỂN THỊ MẪU NGÂN HÀNG (CHỈ KHI CHỌN CHUYỂN KHOẢN)
            // =====================================================
            if (_selectedPaymentMethod == 'Chuyển khoản')
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance, color: Colors.blue[900]),
                        const SizedBox(width: 8),
                        Text('Thông tin chuyển khoản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[900])),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildBankInfoRow('Ngân hàng:', 'Vietcombank (VCB)'),
                    _buildBankInfoRow('Số tài khoản:', '0123 4567 8999'),
                    _buildBankInfoRow('Chủ tài khoản:', 'NGUYEN TAI TAN'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
                      child: Text('Nội dung: Thanh toan ve ${widget.docId.substring(0, 5)}',
                          style: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: Colors.red)
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),

      // =====================================================
      // 5. NÚT XÁC NHẬN
      // =====================================================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            // Bắt lỗi nếu khách không điền thông tin
            if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng điền Họ tên và Số điện thoại!'), backgroundColor: Colors.red),
              );
              return;
            }

            // Lưu dữ liệu thông tin khách hàng và cập nhật status lên Firebase
            await FirebaseFirestore.instance.collection('bookings').doc(widget.docId).update({
              'status': 'paid',
              'paymentMethod': _selectedPaymentMethod,
              'customerName': _nameController.text.trim(),
              'customerPhone': _phoneController.text.trim(),
              'customerEmail': _emailController.text.trim(),
            });

            if (context.mounted) {
              Navigator.pop(context); // Quay về màn hình Lịch sử
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thanh toán thành công!'), backgroundColor: Colors.green),
              );
            }
          },
          child: const Text('XÁC NHẬN THANH TOÁN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  // Widget hỗ trợ vẽ dòng chữ Thông tin Giao dịch
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  // Widget hỗ trợ vẽ dòng chữ Thông tin Ngân hàng
  Widget _buildBankInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
        ],
      ),
    );
  }
}
