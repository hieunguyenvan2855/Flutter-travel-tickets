import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/tour_model.dart';
import '../../models/user_model.dart';
import '../admin/add_tour_screen.dart';
import 'tour_detail_screen.dart'; // Thêm màn hình chi tiết

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dbService = Provider.of<DatabaseService>(context);
    final user = Provider.of<User?>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chào mừng bạn', style: TextStyle(fontSize: 14, color: Colors.white70)),
            Text('Khám Phá Việt Nam', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        actions: [
          if (user != null)
            FutureBuilder<UserModel?>(
              future: authService.getUserData(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.role == 'admin') {
                  return IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTourScreen())),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Tour>>(
        stream: dbService.tours,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tours = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner hoặc Tiêu đề mục
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Tất cả Tour phổ biến', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: tours.length,
                  itemBuilder: (context, index) {
                    final tour = tours[index];
                    return GestureDetector(
                      onTap: () {
                        // Chuyển sang màn hình Chi tiết Tour
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TourDetailScreen(tour: tour))
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                  child: Image.network(
                                    tour.imageUrl,
                                    height: 200, width: double.infinity, fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(height: 200, color: Colors.grey),
                                  ),
                                ),
                                Positioned(
                                  top: 10, right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                                    child: Text('${tour.price}đ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tour.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text(tour.location, style: const TextStyle(color: Colors.grey)),
                                      const Spacer(),
                                      const Icon(Icons.person, size: 16, color: Colors.grey),
                                      Text(' Còn ${tour.availableSlots} chỗ', style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
