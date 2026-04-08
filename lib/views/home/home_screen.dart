import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/tour_model.dart';
import '../../models/user_model.dart';
import '../admin/add_tour_screen.dart';
import '../admin/admin_booking_screen.dart';
import 'tour_detail_screen.dart';
import 'profile_screen.dart';
import 'booking_history_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _searchQuery = "";
  String _selectedCategory = "Tất cả";
  double _maxPrice = 100000000;

  final List<String> _categories = ["Tất cả", "Biển đảo", "Vùng núi", "Văn hóa"];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dbService = Provider.of<DatabaseService>(context);
    final user = Provider.of<User?>(context);

    return FutureBuilder<UserModel?>(
      future: user != null ? authService.getUserData(user.uid) : null,
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final isAdmin = userData?.role == 'admin';

        List<Widget> pages = [
          _buildExplorePage(dbService, isAdmin),
          if (!isAdmin) const BookingHistoryScreen(),
          const ProfileScreen(),
        ];

        List<BottomNavigationBarItem> navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Khám phá'),
          if (!isAdmin) const BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), activeIcon: Icon(Icons.confirmation_number), label: 'Vé của tôi'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Cá nhân'),
        ];

        if (_selectedIndex >= pages.length) _selectedIndex = 0;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: const Color(0xFF0D47A1),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: navItems,
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF0D47A1),
            child: const Icon(Icons.smart_toy, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatBotScreen())),
          ),
        );
      }
    );
  }

  Widget _buildExplorePage(DatabaseService dbService, bool isAdmin) {
    return StreamBuilder<List<Tour>>(
      stream: dbService.tours,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final allTours = snapshot.data!;
        final filteredTours = allTours.where((t) {
          final matchesSearch = t.title.toLowerCase().contains(_searchQuery) || t.location.toLowerCase().contains(_searchQuery);
          final matchesCategory = _selectedCategory == "Tất cả" || t.category == _selectedCategory;
          return matchesSearch && matchesCategory && t.price <= _maxPrice;
        }).toList();

        final spotlightTours = allTours.take(3).toList();

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: const Color(0xFF0D47A1),
              title: const Text('TravelVN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
              actions: [
                if (isAdmin)
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
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.white,
                      filled: true,
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
                  if (spotlightTours.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                      child: Text('Tour Nổi Bật', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    CarouselSlider(
                      options: CarouselOptions(height: 200, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.85),
                      items: spotlightTours.map((tour) => _buildTourCardImage(tour)).toList(),
                    ),
                  ],
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: _categories.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          onSelected: (selected) => setState(() => _selectedCategory = cat),
                          selectedColor: const Color(0xFF0D47A1),
                          labelStyle: TextStyle(color: _selectedCategory == cat ? Colors.white : Colors.black),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      )).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Text('Giá tối đa: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${(_maxPrice/1000000).toStringAsFixed(0)}tr', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        Expanded(child: Slider(value: _maxPrice, min: 0, max: 100000000, divisions: 20, onChanged: (val) => setState(() => _maxPrice = val))),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Text('Dành cho bạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildTourListItem(context, filteredTours[index]),
                  childCount: filteredTours.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        );
      },
    );
  }

  // HÀM HIỂN THỊ ẢNH THÔNG MINH: TỰ ĐỘNG CHỌN ASSET HOẶC NETWORK
  Widget _buildTourImage(String path, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, height: height, width: width, fit: fit, errorBuilder: (context, error, stackTrace) {
        return Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported));
      });
    } else {
      return CachedNetworkImage(
        imageUrl: path,
        height: height,
        width: width,
        fit: fit,
        placeholder: (context, url) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
        errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
      );
    }
  }

  Widget _buildTourCardImage(Tour tour) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TourDetailScreen(tour: tour))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _buildTourImage(tour.imageUrl, width: double.infinity),
      ),
    );
  }

  Widget _buildTourListItem(BuildContext context, Tour tour) {
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
              child: _buildTourImage(tour.imageUrl, height: 200, width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(tour.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text('${NumberFormat('#,###').format(tour.price.toInt())}đ', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 17)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(tour.location, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const Spacer(),
                      const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Còn ${tour.availableSlots} chỗ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
