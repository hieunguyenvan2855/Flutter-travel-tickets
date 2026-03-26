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
          // App Bar với ảnh Tour
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(tour.title, style: const TextStyle(shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
              background: Image.network(tour.imageUrl, fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông tin cơ bản
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.location_on, size: 16),
                        label: Text(tour.location),
                      ),
                      Text('${tour.price}đ', 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Giới thiệu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(tour.description, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  
                  const SizedBox(height: 24),
                  const Text('Điểm nổi bật', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...tour.highlights.map((h) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Text(h, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  )),

                  const SizedBox(height: 24),
                  const Text('Lịch trình dự kiến', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: Text(tour.schedule, style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
                  ),
                  const SizedBox(height: 100), // Khoảng trống cho nút Bottom
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Còn trống', style: TextStyle(color: Colors.grey)),
                Text('${tour.availableSlots} chỗ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: tour.availableSlots > 0 ? () async {
                  final result = await dbService.bookTour(user?.uid ?? 'guest', tour.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                } : null,
                child: const Text('ĐẶT VÉ NGAY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
