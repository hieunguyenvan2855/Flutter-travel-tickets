import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tour_model.dart';
import '../../services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TourDetailScreen extends StatelessWidget {
  final Tour tour;
  const TourDetailScreen({super.key, required this.tour});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final dbService = Provider.of<DatabaseService>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar với ảnh Tour + Hero animation
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(tour.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(2, 2))]
                ),
              ),
              background: Hero(
                tag: 'tour-${tour.id}',
                child: Image.network(tour.imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Giá và Địa điểm
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(tour.location, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Text('${tour.price.toInt()}đ',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('Giới thiệu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(tour.description, style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5)),
                  
                  const SizedBox(height: 24),
                  const Text('Điểm nổi bật', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (tour.highlights.isEmpty)
                    const Text('Đang cập nhật...', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                  else
                    ...tour.highlights.map((h) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(h, style: const TextStyle(fontSize: 16))),
                        ],
                      ),
                    )),

                  const SizedBox(height: 24),
                  const Text('Lịch trình dự kiến', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!)
                    ),
                    child: Text(
                      tour.schedule.isNotEmpty ? tour.schedule : 'Liên hệ để biết thêm chi tiết',
                      style: const TextStyle(fontSize: 15, height: 1.4)
                    ),
                  ),

                  if (tour.geoPoint != null) ...[
                    const SizedBox(height: 24),
                    const Text('Vị trí trên bản đồ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Icon(Icons.map, size: 50, color: Colors.grey)),
                    ),
                  ],

                  const SizedBox(height: 120), // Khoảng trống cho nút Bottom
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trạng thái', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('${tour.availableSlots} chỗ trống',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tour.availableSlots > 0 ? Colors.green : Colors.red)),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: tour.availableSlots > 0 ? () async {
                  _showBookingDialog(context, dbService, user?.uid ?? 'guest', tour.id);
                } : null,
                child: const Text('ĐẶT VÉ NGAY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context, DatabaseService dbService, String userId, String tourId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đặt vé'),
        content: const Text('Bạn có chắc chắn muốn đặt tour này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await dbService.bookTour(userId, tourId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
              }
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }
}
