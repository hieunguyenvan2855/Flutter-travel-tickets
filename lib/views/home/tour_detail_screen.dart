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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'tour-${tour.id}',
                child: Image.network(tour.imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tour.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue, size: 18),
                      Text(tour.location, style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      Text('${tour.price.toInt()}đ', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const Divider(height: 40),
                  const Text('Giới thiệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(tour.description, style: const TextStyle(color: Colors.black87, height: 1.5)),
                  const SizedBox(height: 30),
                  const Text('LỊCH TRÌNH', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  // Giao diện Lịch trình dạng Accordion/List như web bạn gửi
                  ...tour.scheduleItems.map((item) => _buildScheduleTile(item)),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBookingPanel(context, dbService, user),
    );
  }

  Widget _buildScheduleTile(ScheduleItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(item.content, style: const TextStyle(height: 1.5, color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingPanel(BuildContext context, DatabaseService dbService, User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Giá từ', style: TextStyle(color: Colors.grey)),
                Text('${tour.price.toInt()}đ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final res = await dbService.bookTour(user?.uid ?? 'guest', tour.id);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
            },
            child: const Text('ĐẶT VÉ NGAY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
