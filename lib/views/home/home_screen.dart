import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart'; // Sử dụng lại Carousel
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/tour_model.dart';
import '../../models/user_model.dart';
import '../admin/add_tour_screen.dart';
import '../admin/admin_booking_screen.dart';
import 'tour_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _searchQuery = "";
  String _selectedCategory = "Tất cả";

  final List<String> _categories = ["Tất cả", "Biển đảo", "Vùng núi", "Văn hóa", "Nước ngoài"];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dbService = Provider.of<DatabaseService>(context);
    final user = Provider.of<User?>(context);

    List<Widget> _pages = [
      _buildExplorePage(dbService, authService, user),
      const Center(child: Text("Danh sách vé đã đặt sẽ hiện ở đây")),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50], // Nền xám nhạt cho sang trọng
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Khám phá'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), activeIcon: Icon(Icons.confirmation_number), label: 'Vé của tôi'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }

  Widget _buildExplorePage(DatabaseService dbService, AuthService authService, User? user) {
    return StreamBuilder<List<Tour>>(
      stream: dbService.tours,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final allTours = snapshot.data!;
        // Lọc danh sách tour
        final filteredTours = allTours.where((t) {
          final matchesSearch = t.title.toLowerCase().contains(_searchQuery) || t.location.toLowerCase().contains(_searchQuery);
          final matchesCategory = _selectedCategory == "Tất cả" || t.location.contains(_selectedCategory.replaceAll("Vùng ", ""));
          return matchesSearch;
        }).toList();

        // Lấy 3 tour đầu làm Spotlight
        final spotlightTours = allTours.take(3).toList();

        return CustomScrollView(
          slivers: [
            // 1. Header & Tìm kiếm
            SliverAppBar(
              expandedHeight: 130,
              floating: true,
              pinned: true,
              backgroundColor: Colors.blue[900],
              elevation: 0,
              title: const Text('TravelVN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
              actions: [
                if (user != null)
                  FutureBuilder<UserModel?>(
                    future: authService.getUserData(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.role == 'admin') {
                        return IconButton(
                          icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminBookingScreen())),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTourScreen())),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Bạn muốn đi đâu?',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Spotlight (Carousel)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Text('Tour Nổi Bật', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 200,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      aspectRatio: 16/9,
                      viewportFraction: 0.85,
                    ),
                    items: spotlightTours.map((tour) {
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TourDetailScreen(tour: tour))),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(image: NetworkImage(tour.imageUrl), fit: BoxFit.cover),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                              ),
                            ),
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tour.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                Text(tour.location, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // 3. Danh mục (Filter)
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Row(
                      children: _categories.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          onSelected: (selected) => setState(() => _selectedCategory = cat),
                          selectedColor: Colors.blue[900],
                          labelStyle: TextStyle(color: _selectedCategory == cat ? Colors.white : Colors.black),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      )).toList(),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text('Dành cho bạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // 4. Danh sách Tour
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildTourCard(context, filteredTours[index]),
                  childCount: filteredTours.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        );
      },
    );
  }

  Widget _buildTourCard(BuildContext context, Tour tour) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TourDetailScreen(tour: tour))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(tour.imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tour.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(tour.location, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const Spacer(),
                      Text('${tour.price.toInt()}đ', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
