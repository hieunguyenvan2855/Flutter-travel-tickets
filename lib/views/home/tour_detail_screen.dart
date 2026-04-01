import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/tour_model.dart';
import '../../services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TourDetailScreen extends StatefulWidget {
  final Tour tour;
  const TourDetailScreen({super.key, required this.tour});

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen> {
  Position? _currentPosition;
  double _distanceToDestination = 0;
  bool _isCheckingDistance = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted && widget.tour.geoPoint != null) {
          setState(() {
            _currentPosition = position;
            _distanceToDestination = Geolocator.distanceBetween(
              position.latitude, position.longitude,
              widget.tour.geoPoint!.latitude, widget.tour.geoPoint!.longitude,
            );
          });
        }
      }
    } catch (e) {
      print('Location error: $e');
    }
  }

  Future<void> _openSupportChat(String platform) async {
    String url = platform == 'zalo' 
      ? 'https://zalo.me/0123456789' 
      : 'https://m.me/your_page_id';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

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
                tag: 'tour-${widget.tour.id}',
                child: Image.network(widget.tour.imageUrl, fit: BoxFit.cover),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue, size: 18),
                      Text(widget.tour.location, style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      Text('${widget.tour.price.toInt()}đ', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const Divider(height: 40),
                  const Text('LỊCH TRÌNH', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ...widget.tour.scheduleItems.map((item) => _buildScheduleTile(item)),
                  
                  if (widget.tour.geoPoint != null) ...[
                    const SizedBox(height: 30),
                    const Text('CHECK-IN GPS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _isCheckingDistance ? null : () async {
                        setState(() => _isCheckingDistance = true);
                        await Future.delayed(const Duration(seconds: 1)); // Giả lập quét
                        _initializeLocation();
                        setState(() => _isCheckingDistance = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Khoảng cách hiện tại: ${_distanceToDestination.toStringAsFixed(0)}m'))
                        );
                      },
                      icon: const Icon(Icons.location_searching),
                      label: Text(_isCheckingDistance ? 'Đang xác vị trí...' : 'Xác nhận Check-in'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    ),
                  ],
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBookingPanel(context, dbService, user),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupportMenu(context),
        backgroundColor: Colors.blue[900],
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  void _showSupportMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.message, color: Colors.blue),
            title: const Text('Hỗ trợ qua Zalo'),
            onTap: () => _openSupportChat('zalo'),
          ),
          ListTile(
            leading: const Icon(Icons.facebook, color: Colors.blue),
            title: const Text('Hỗ trợ qua Messenger'),
            onTap: () => _openSupportChat('messenger'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(ScheduleItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [Padding(padding: const EdgeInsets.all(15), child: Text(item.content))],
      ),
    );
  }

  Widget _buildBookingPanel(BuildContext context, DatabaseService dbService, User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 90,
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Row(
        children: [
          Expanded(child: Text('${widget.tour.price.toInt()}đ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
            onPressed: () async {
              final res = await dbService.bookTour(user?.uid ?? 'guest', widget.tour.id);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
            },
            child: const Text('ĐẶT VÉ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
