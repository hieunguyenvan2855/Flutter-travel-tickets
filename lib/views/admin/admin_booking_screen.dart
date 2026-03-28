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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Đơn hàng'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Booking>>(
        stream: dbService.allBookings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final bookings = snapshot.data ?? [];
          
          if (bookings.isEmpty) {
            return const Center(child: Text('Chưa có đơn hàng nào.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mã đơn: ${booking.bookingId.substring(0, 8).toUpperCase()}', 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          _buildStatusChip(booking.status),
                        ],
                      ),
                      const Divider(height: 20),
                      Text('Khách hàng ID: ${booking.userId}', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Tour ID: ${booking.tourId}', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(booking.timestamp)}', 
                        style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('Tổng tiền: ${booking.totalPrice.toInt()}đ', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                      
                      if (booking.status == 'pending') ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('XÁC NHẬN ĐƠN HÀNG'),
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
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'Chờ xác nhận';
        break;
      case 'confirmed':
        color = Colors.green;
        text = 'Đã xác nhận';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Đã hủy';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmBooking(BuildContext context, DatabaseService dbService, String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn xác nhận đơn hàng này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await dbService.confirmBooking(bookingId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xác nhận đơn hàng thành công!')));
              }
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }
}
