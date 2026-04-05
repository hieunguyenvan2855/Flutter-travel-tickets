import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../models/tour_model.dart';
import '../../models/review_model.dart';
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
  int _currentImageIndex = 0;

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
      debugPrint('Location error: $e');
    }
  }

  void _showBookingForm(BuildContext context, DatabaseService dbService, User? user) {
    int ticketCount = 1;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final phoneController = TextEditingController();
    final voucherController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: SizedBox(width: 50, child: Divider(thickness: 4))),
              const SizedBox(height: 10),
              const Text("Chi tiết đặt vé", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              
              const Text("Chọn ngày khởi hành", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setModalState(() => selectedDate = picked);
                  },
                  child: const Text("Thay đổi"),
                ),
              ),
              const Divider(),

              const Text("Số lượng khách", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Người lớn", style: TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      IconButton(
                        onPressed: ticketCount > 1 ? () => setModalState(() => ticketCount--) : null,
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.blue),
                      ),
                      Text("$ticketCount", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => setModalState(() => ticketCount++),
                        icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                      ),
                    ],
                  )
                ],
              ),
              const Divider(),

              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Số điện thoại liên hệ", prefixIcon: Icon(Icons.phone), border: InputBorder.none),
                keyboardType: TextInputType.phone,
              ),
              const Divider(),
              TextField(
                controller: voucherController,
                decoration: const InputDecoration(labelText: "Mã giảm giá", prefixIcon: Icon(Icons.card_giftcard), border: InputBorder.none),
              ),
              
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tổng tạm tính:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    Text("${NumberFormat('#,###').format(widget.tour.price.toInt() * ticketCount)}đ", 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: () async {
                    if (phoneController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập số điện thoại")));
                      return;
                    }
                    final res = await dbService.bookTour(
                      userId: user?.uid ?? 'guest', 
                      tourId: widget.tour.id,
                      tickets: ticketCount,
                      phone: phoneController.text,
                      travelDate: DateFormat('dd/MM/yyyy').format(selectedDate),
                      voucherCode: voucherController.text,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
                    }
                  },
                  child: const Text("XÁC NHẬN ĐẶT VÉ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final dbService = Provider.of<DatabaseService>(context);

    final List<String> albumImages = widget.tour.images.isNotEmpty 
        ? widget.tour.images 
        : [widget.tour.imageUrl];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 400,
                      viewportFraction: 1.0,
                      enlargeCenterPage: false,
                      onPageChanged: (index, reason) {
                        setState(() => _currentImageIndex = index);
                      },
                    ),
                    items: albumImages.map((url) {
                      return Image.network(url, fit: BoxFit.cover, width: double.infinity);
                    }).toList(),
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
                  Text(widget.tour.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue, size: 18),
                      Text(widget.tour.location, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                      const Spacer(),
                      Text('${NumberFormat('#,###').format(widget.tour.price.toInt())}đ', 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const Divider(height: 40),
                  
                  const Text('Giới thiệu chuyến đi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(widget.tour.description, style: const TextStyle(color: Colors.black87, height: 1.6)),
                  
                  const SizedBox(height: 30),
                  const Text('Điểm nổi bật', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...widget.tour.highlights.map((h) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 18), const SizedBox(width: 10), Text(h)]),
                  )),

                  const Divider(height: 40),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Đánh giá từ khách hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () {}, child: const Text('Xem tất cả')),
                    ],
                  ),
                  _buildReviewSection(dbService),
                  
                  const Divider(height: 40),

                  const Text('LỊCH TRÌNH CHI TIẾT', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  const SizedBox(height: 15),
                  ...widget.tour.scheduleItems.map((item) => _buildScheduleTile(item)),
                  
                  if (widget.tour.geoPoint != null) ...[
                    const SizedBox(height: 30),
                    _buildCheckInSection(user, dbService),
                  ],
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

  Widget _buildReviewSection(DatabaseService dbService) {
    return StreamBuilder<List<Review>>(
      stream: dbService.getTourReviews(widget.tour.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Chưa có đánh giá nào cho tour này.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          );
        }
        final reviews = snapshot.data!;
        return Column(children: reviews.take(3).map((r) => _buildReviewTile(r)).toList());
      },
    );
  }

  Widget _buildReviewTile(Review r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 15, backgroundColor: Colors.blue[100], child: Text(r.userName[0].toUpperCase())),
              const SizedBox(width: 10),
              Text(r.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              RatingBarIndicator(rating: r.rating, itemBuilder: (c, i) => const Icon(Icons.star, color: Colors.amber), itemCount: 5, itemSize: 14),
            ],
          ),
          const SizedBox(height: 8),
          Text(r.comment, style: const TextStyle(color: Colors.black87, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(ScheduleItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: ExpansionTile(
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        children: [Padding(padding: const EdgeInsets.all(15), child: Text(item.content, style: const TextStyle(height: 1.5, color: Colors.black54)))],
      ),
    );
  }

  Widget _buildCheckInSection(User? user, DatabaseService dbService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('XÁC NHẬN ĐIỂM ĐẾN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _isCheckingDistance ? null : () async {
            setState(() => _isCheckingDistance = true);
            await Future.delayed(const Duration(seconds: 1));
            _initializeLocation();
            setState(() => _isCheckingDistance = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bạn cách điểm đến ${_distanceToDestination.toStringAsFixed(0)}m')));
          },
          icon: const Icon(Icons.location_searching),
          label: Text(_isCheckingDistance ? 'Đang định vị...' : 'Check-in tại đây'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ],
    );
  }

  Widget _buildBookingPanel(BuildContext context, DatabaseService dbService, User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 100,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))]),
      child: Row(
        children: [
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Giá từ', style: TextStyle(color: Colors.grey)),
            Text('${NumberFormat('#,###').format(widget.tour.price.toInt())}đ', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
          ])),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            onPressed: () => _showBookingForm(context, dbService, user),
            child: const Text('ĐẶT VÉ NGAY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
