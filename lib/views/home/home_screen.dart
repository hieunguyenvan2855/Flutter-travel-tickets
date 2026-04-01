import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/tour_model.dart';
import '../../models/user_model.dart';
import '../admin/add_tour_screen.dart';
import '../admin/admin_booking_screen.dart';
import 'tour_detail_screen.dart';
import 'profile_screen.dart';
import 'booking_history_screen.dart';
import '../admin/revenue_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _searchQuery = "";
  String _selectedCategory = "Tất cả";
  double _maxPrice = 20000000;

  final List<String> _categories = ["Tất cả", "Biển đảo", "Vùng núi", "Văn hóa", "Nước ngoài"];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dbService = Provider.of<DatabaseService>(context);
    final user = Provider.of<User?>(context);

    return FutureBuilder<UserModel?>(
      future: user != null ? authService.getUserData(user.uid) : null,
      builder: (context, snapshot) {
        final isAdmin = snapshot.data?.role == 'admin';

        List<Widget> _pages = [
          _buildExplorePage(dbService, authService, user, isAdmin),
          const BookingHistoryScreen(),
          const ProfileScreen(),
        ];

        return Scaffold(
          backgroundColor: Colors.grey[50],
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
    );
  }

  Widget _buildExplorePage(DatabaseService dbService, AuthService authService, User? user, bool isAdmin) {
    return StreamBuilder<List<Tour>>(
      stream: dbService.tours,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final allTours = snapshot.data!;
        final filteredTours = allTours.where((t) {
          final matchesSearch = t.title.toLowerCase().contains(_searchQuery) || t.location.toLowerCase().contains(_searchQuery);
          final matchesCategory = _selectedCategory == "Tất cả" || t.category == _selectedCategory;
          final matchesPrice = t.price <= _maxPrice;
          return matchesSearch && matchesCategory && matchesPrice;
        }).toList();

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 130,
              floating: true,
              pinned: true,
              backgroundColor: Colors.blue[900],
              title: const Text('TravelVN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
              actions: [
                if (isAdmin) ...[
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminBookingScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTourScreen())),
                  ),
                ]
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Text('Tour Nổi Bật', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  CarouselSlider(
                    options: CarouselOptions(height: 200, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.85),
                    items: allTours.take(3).map((tour) {
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TourDetailScreen(tour: tour))),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(image: NetworkImage(tour.imageUrl), fit: BoxFit.cover),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Text('Giá tối đa: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${(_maxPrice/1000000).toStringAsFixed(0)}tr', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Slider(
                            value: _maxPrice, min: 0, max: 100000000, divisions: 20,
                            onChanged: (val) => setState(() => _maxPrice = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Dành cho bạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildTourCard(context, filteredTours[index]),
                  childCount: filteredTours.length,
                ),
              ),
            ),
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
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(tour.imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Expanded(child: Text(tour.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Text('${tour.price.toInt()}đ', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
