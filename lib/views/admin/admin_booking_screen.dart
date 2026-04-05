import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../services/database_service.dart';

class AdminBookingScreen extends StatelessWidget {
  const AdminBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.orange,
            isScrollable: true,
            tabs: [
              Tab(text: 'CHỜ THANH TOÁN'),
              Tab(text: 'ĐÃ THANH TOÁN'),
              Tab(text: 'ĐÃ HỦY'),
            ],
          ),
        ),
        body: StreamBuilder<List<Booking>>(
          stream: dbService.allBookings,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final allBookings = snapshot.data ?? [];
            final pendingBookings = allBookings.where((b) => b.status == 'pending').toList();
            final paidBookings = allBookings.where((b) => b.status == 'paid' || b.status == 'confirmed').toList();
            final cancelledBookings = allBookings.where((b) => b.status == 'cancelled').toList();

            return TabBarView(
              children: [
                _buildBookingList(context, pendingBookings, dbService),
                _buildBookingList(context, paidBookings, dbService),
                _buildBookingList(context, cancelledBookings, dbService),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingList(BuildContext context, List<Booking> bookings, DatabaseService dbService) {
    if (bookings.isEmpty) {
      return const Center(child: Text('Không có đơn hàng nào ở mục này.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(booking.tourName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.blue))),
                    _buildStatusChip(booking.status),
                  ],
                ),
                const Divider(height: 30),
                _buildInfoRow(Icons.person, 'Khách: ', booking.userId),
                _buildInfoRow(Icons.calendar_month, 'Ngày: ', DateFormat('dd/MM/yyyy HH:mm').format(booking.timestamp)),
                _buildInfoRow(Icons.payments, 'Tiền: ', '${NumberFormat('#,###').format(booking.totalPrice.toInt())}đ'),
                
                if (booking.status == 'paid') ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('XÁC NHẬN ĐÃ NHẬN TIỀN', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _confirmBooking(context, dbService, booking.bookingId),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case 'pending': color = Colors.orange; text = 'Chờ khách trả'; break;
      case 'paid': color = Colors.blue; text = 'Khách đã trả'; break;
      case 'confirmed': color = Colors.green; text = 'Đã hoàn tất'; break;
      case 'cancelled': color = Colors.red; text = 'Đã hủy'; break;
      default: color = Colors.grey; text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmBooking(BuildContext context, DatabaseService dbService, String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận doanh thu'),
        content: const Text('Bạn có chắc chắn đã nhận được tiền? Hệ thống sẽ tích điểm cho khách ngay sau đó.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(context);
              try {
                // HIỆN LOADING TRƯỚC KHI GỌI HÀM
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang xử lý xác nhận...'), duration: Duration(seconds: 1)));
                
                await dbService.confirmBooking(bookingId);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xác nhận thành công!'), backgroundColor: Colors.green)
                  );
                }
              } catch (e) {
                // NẾU LỖI THÌ HIỆN THÔNG BÁO ĐỎ ĐỂ BIẾT LÝ DO
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red)
                  );
                }
              }
            },
            child: const Text('Xác nhận ngay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
