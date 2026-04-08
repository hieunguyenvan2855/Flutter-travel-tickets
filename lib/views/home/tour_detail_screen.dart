import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/tour_model.dart';
import '../../models/user_model.dart';
import '../../models/review_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../admin/edit_tour_screen.dart';

class TourDetailScreen extends StatefulWidget {
  final Tour tour;
  const TourDetailScreen({super.key, required this.tour});

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen> {
  int _currentImageIndex = 0;

  // HÀM ĐIỀU HƯỚNG MAPS THÔNG MINH
  Future<void> _launchMaps() async {
    String query;
    if (widget.tour.geoPoint != null && widget.tour.geoPoint!.latitude != 0) {
      // Nếu có tọa độ GPS -> Dùng tọa độ
      query = '${widget.tour.geoPoint!.latitude},${widget.tour.geoPoint!.longitude}';
    } else {
      // Nếu thiếu GPS -> Dùng Tên Tour + Địa điểm để Google Maps tự tìm
      query = Uri.encodeComponent('${widget.tour.title} ${widget.tour.location}');
    }
    
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final user = Provider.of<User?>(context);
    final authService = Provider.of<AuthService>(context);
    
    final List<String> albumImages = widget.tour.images.isNotEmpty ? widget.tour.images : [widget.tour.imageUrl];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.blue[900],
            actions: [
              if (user != null)
                FutureBuilder<UserModel?>(
                  future: authService.getUserData(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.role == 'admin') {
                      return IconButton(
                        icon: const Icon(Icons.edit_note, color: Colors.white, size: 28),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditTourScreen(tour: widget.tour))),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 350,
                      viewportFraction: 1.0,
                      onPageChanged: (index, reason) => setState(() => _currentImageIndex = index),
                    ),
                    items: albumImages.map((url) => _buildTourImage(url)).toList(),
                  ),
                  Positioned(
                    bottom: 20, right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: Text('${_currentImageIndex + 1}/${albumImages.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.tour.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  // ĐỊA ĐIỂM NHẤN ĐỂ MỞ MAPS
                  InkWell(
                    onTap: _launchMaps,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue, size: 20),
                          const SizedBox(width: 5),
                          Text(widget.tour.location, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 10),
                          const Icon(Icons.open_in_new, size: 14, color: Colors.blueGrey),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Giá tham khảo:', style: TextStyle(color: Colors.grey)),
                      Text('${NumberFormat('#,###').format(widget.tour.price.toInt())}đ', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const Divider(height: 40),
                  
                  // NÚT MỞ APP GOOGLE MAPS
                  ElevatedButton.icon(
                    onPressed: _launchMaps,
                    icon: const Icon(Icons.directions, color: Colors.white),
                    label: const Text('XEM VỊ TRÍ TRÊN GOOGLE MAPS', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text('Giới thiệu chuyến đi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(widget.tour.description, style: const TextStyle(color: Colors.black87, height: 1.5)),
                  const SizedBox(height: 20),

                  ...widget.tour.highlights.map((h) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 18), const SizedBox(width: 10), Text(h)]),
                  )),
                  const Divider(height: 40),

                  const Text('LỊCH TRÌNH CHI TIẾT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ...widget.tour.scheduleItems.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                    child: ExpansionTile(
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      children: [Padding(padding: const EdgeInsets.all(15), child: Text(item.content, style: const TextStyle(height: 1.5, color: Colors.black87)))],
                    ),
                  )),
                  const Divider(height: 40),
                  const Text('Đánh giá từ khách hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildReviewSection(dbService),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildTourImage(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover, width: double.infinity);
    }
    return CachedNetworkImage(
      imageUrl: path,
      fit: BoxFit.cover,
      width: double.infinity,
      errorWidget: (c, e, s) => Container(color: Colors.blue[900], child: const Icon(Icons.image, color: Colors.white)),
    );
  }

  Widget _buildReviewSection(DatabaseService dbService) {
    return StreamBuilder<List<Review>>(
      stream: dbService.getTourReviews(widget.tour.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('Chưa có đánh giá nào.'));
        return Column(children: snapshot.data!.take(3).map((r) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundColor: Colors.blue[100], child: Text(r.userName[0])),
          title: Row(children: [Text(r.userName, style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), RatingBarIndicator(rating: r.rating, itemBuilder: (c, i) => const Icon(Icons.star, color: Colors.amber), itemCount: 5, itemSize: 12)]),
          subtitle: Text(r.comment),
        )).toList());
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 90,
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Row(
        children: [
          Expanded(child: Text('${NumberFormat('#,###').format(widget.tour.price.toInt())}đ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {},
            child: const Text('ĐẶT VÉ NGAY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
