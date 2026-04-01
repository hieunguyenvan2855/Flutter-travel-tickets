import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/booking_model.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final dbService = Provider.of<DatabaseService>(context);

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));
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
            tabs: [Tab(text: "Chờ thanh toán"), Tab(text: "Đã thanh toán")],
          ),
        ),
        body: StreamBuilder<List<Booking>>(
          stream: dbService.getUserBookings(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final all = snapshot.data ?? [];
            final pending = all.where((b) => b.status == 'pending' || b.status == 'confirmed').toList();
            final paid = all.where((b) => b.status == 'paid').toList();

            return TabBarView(
              children: [
                _buildList(context, pending, true, dbService),
                _buildList(context, paid, false, dbService),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Booking> bookings, bool isPending, DatabaseService dbService) {
    if (bookings.isEmpty) return const Center(child: Text("Chưa có dữ liệu ở mục này"));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) => _buildCard(context, bookings[index], isPending, dbService),
    );
  }

  Widget _buildCard(BuildContext context, Booking b, bool isPending, DatabaseService dbService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(b.tourName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                _buildStatusChip(b.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Mã đơn: ${b.bookingId.substring(0, b.bookingId.length > 8 ? 8 : b.bookingId.length).toUpperCase()}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd/MM/yyyy HH:mm').format(b.timestamp), style: const TextStyle(color: Colors.black54)),
                Text('${b.totalPrice.toInt()}đ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showPaymentForm(context, b, dbService),
                  child: const Text("THANH TOÁN NGAY", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String s) {
    Color color = s == 'paid' ? Colors.green : Colors.orange;
    String text = s == 'paid' ? 'Đã thanh toán' : 'Chờ thanh toán';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _showPaymentForm(BuildContext context, Booking b, DatabaseService dbService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300], // FIXED: Removed const from parent Center to use dynamic Color
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Thanh toán đơn hàng", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            _buildInfoRow("Tour", b.tourName),
            _buildInfoRow("Tổng tiền", "${b.totalPrice.toInt()}đ"),
            const SizedBox(height: 30),
            const Text("Chọn phương thức thanh toán", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildPaymentMethod(Icons.account_balance, "Chuyển khoản ngân hàng"),
            _buildPaymentMethod(Icons.wallet, "Ví điện tử MoMo"),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () async {
                  await dbService.confirmPayment(b.bookingId);
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thanh toán thành công!"), backgroundColor: Colors.green));
                  }
                },
                child: const Text("XÁC NHẬN THANH TOÁN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[900]),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          const Icon(Icons.radio_button_off, color: Colors.grey),
        ],
      ),
    );
  }
}
