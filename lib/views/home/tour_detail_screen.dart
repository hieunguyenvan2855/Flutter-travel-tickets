import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  GoogleMapController? _mapController;
  Position? _currentPosition;
  double _distanceToDestination = 0;
  bool _isCheckingDistance = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  /// Khởi tạo vị trí hiện tại từ geolocator
  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng bật định vị')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cấp quyền định vị bị từ chối')),
            );
          }
          return;
        }
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() => _currentPosition = position);
        _calculateDistanceToDestination();
      }
    } catch (e) {
      if (mounted) {
        print('Lỗi lấy vị trí: $e');
      }
    }
  }

  /// Tính khoảng cách từ vị trí hiện tại đến điểm đến
  void _calculateDistanceToDestination() {
    if (_currentPosition == null || widget.tour.geoPoint == null) return;

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.tour.geoPoint!.latitude,
      widget.tour.geoPoint!.longitude,
    );

    setState(() => _distanceToDestination = distance);
  }

  /// Xử lý Check-in GPS
  Future<void> _handleGPSCheckIn(User? user, DatabaseService dbService) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập trước')),
      );
      return;
    }

    if (_currentPosition == null || widget.tour.geoPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xác định vị trí')),
      );
      return;
    }

    setState(() => _isCheckingDistance = true);

    try {
      // Lấy vị trí mới nhất
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        widget.tour.geoPoint!.latitude,
        widget.tour.geoPoint!.longitude,
      );

      if (distance <= 500) {
        // Check-in thành công
        await dbService.saveCheckIn(
          userId: user.uid,
          tourId: widget.tour.id,
          currentLat: position.latitude,
          currentLng: position.longitude,
          destLat: widget.tour.geoPoint!.latitude,
          destLng: widget.tour.geoPoint!.longitude,
          distance: distance,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✓ Check-in thành công! Khoảng cách: ${distance.toStringAsFixed(0)}m'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✗ Bạn cách điểm đến ${distance.toStringAsFixed(0)}m. Cần < 500m để check-in'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi check-in: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingDistance = false);
      }
    }
  }

  /// Mở trực tiếp ứng dụng Zalo hoặc Messenger
  Future<void> _openSupportChat(String platform) async {
    String url = '';
    String msg = 'Xin mời hỗ trợ tôi với tour: ${widget.tour.title}';

    if (platform == 'zalo') {
      // Định dạng URL Zalo (thay số điện thoại của công ty)
      url = 'https://zalo.me/0123456789?text=$msg';
    } else if (platform == 'messenger') {
      // Định dạng URL Messenger (thay page ID của công ty)
      url = 'https://m.me/your_page_id?text=$msg';
    }

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể mở $platform')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  /// Mở Google Maps
  Future<void> _openGoogleMaps() async {
    final lat = widget.tour.geoPoint?.latitude;
    final lng = widget.tour.geoPoint?.longitude;

    if (lat == null || lng == null) return;

    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    try {
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl),
            mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở Google Maps')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
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
                  Text(widget.tour.title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.blue, size: 18),
                      Text(widget.tour.location,
                          style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      Text('${widget.tour.price.toInt()}đ',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                    ],
                  ),
                  const Divider(height: 40),
                  const Text('Giới thiệu',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(widget.tour.description,
                      style:
                          const TextStyle(color: Colors.black87, height: 1.5)),
                  const SizedBox(height: 30),
                  const Text('LỊCH TRÌNH',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ...widget.tour.scheduleItems
                      .map((item) => _buildScheduleTile(item)),
                  const SizedBox(height: 30),
                  // BẢN ĐỒ
                  if (widget.tour.geoPoint != null) ...[
                    const Text('ĐỊA ĐIỂM TOUR',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          SizedBox(
                            height: 300,
                            child: GestureDetector(
                              onTap: () => _openGoogleMaps(),
                              child: Image.network(
                                'https://maps.googleapis.com/maps/api/staticmap?center=${widget.tour.geoPoint?.latitude},${widget.tour.geoPoint?.longitude}&zoom=16&size=600x300&markers=color:red%7C${widget.tour.geoPoint?.latitude},${widget.tour.geoPoint?.longitude}&style=feature:water%7Celement:labels.text%7Cvisibility:off&key=AIzaSyDWgTCIU0XpXXoHliTsChIK2fJmgsvNlwk',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.location_on,
                                              size: 48,
                                              color: Colors.blue[900]),
                                          const SizedBox(height: 10),
                                          Text(
                                            widget.tour.location,
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue[900]),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Overlay button
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: FloatingActionButton.extended(
                              onPressed: () => _openGoogleMaps(),
                              backgroundColor: Colors.white,
                              icon: Icon(Icons.map, color: Colors.blue[900]),
                              label: Text(
                                'Mở Google Maps',
                                style: TextStyle(color: Colors.blue[900]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (_distanceToDestination > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _distanceToDestination <= 500
                              ? Colors.green[50]
                              : Colors.orange[50],
                          border: Border.all(
                            color: _distanceToDestination <= 500
                                ? Colors.green
                                : Colors.orange,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Khoảng cách: ${_distanceToDestination.toStringAsFixed(0)}m',
                          style: TextStyle(
                            color: _distanceToDestination <= 500
                                ? Colors.green[700]
                                : Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _isCheckingDistance
                          ? null
                          : () => _handleGPSCheckIn(user, dbService),
                      icon: _isCheckingDistance
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.location_on),
                      label: Text(
                        _isCheckingDistance
                            ? 'Đang kiểm tra...'
                            : 'CHECK-IN GPS',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _distanceToDestination <= 500 &&
                                _distanceToDestination > 0
                            ? Colors.green
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
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
      floatingActionButton: _buildSupportFAB(),
    );
  }

  /// Xây dựng Floating Action Button cho hỗ trợ
  Widget? _buildSupportFAB() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // FAB nhỏ cho Zalo
        FloatingActionButton(
          mini: true,
          heroTag: 'zalo_fab',
          backgroundColor: const Color(0xFF0084FF), // Zalo blue
          onPressed: () => _openSupportChat('zalo'),
          child: SvgPicture.asset(
            'assets/images/zalo_logo.svg',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 10),
        // FAB nhỏ cho Messenger
        FloatingActionButton(
          mini: true,
          heroTag: 'messenger_fab',
          backgroundColor: const Color(0xFF0084FF), // Messenger blue
          onPressed: () => _openSupportChat('messenger'),
          child: SvgPicture.asset(
            'assets/images/messenger_logo.svg',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 10),
        // FAB chính
        FloatingActionButton(
          heroTag: 'support_fab',
          backgroundColor: Colors.blue[500],
          onPressed: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Liên hệ với công ty du lịch',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: SvgPicture.asset(
                        'assets/images/zalo_logo.svg',
                        width: 24,
                        height: 24,
                      ),
                      title: const Text('Zalo'),
                      subtitle: const Text('Liên hệ qua Zalo'),
                      onTap: () {
                        Navigator.pop(context);
                        _openSupportChat('zalo');
                      },
                    ),
                    ListTile(
                      leading: SvgPicture.asset(
                        'assets/images/messenger_logo.svg',
                        width: 24,
                        height: 24,
                      ),
                      title: const Text('Messenger'),
                      subtitle: const Text('Liên hệ qua Messenger'),
                      onTap: () {
                        Navigator.pop(context);
                        _openSupportChat('messenger');
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          child: const Icon(Icons.support_agent),
        ),
      ],
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
        title: Text(item.title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black87)),
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(item.content,
                style: const TextStyle(height: 1.5, color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingPanel(
      BuildContext context, DatabaseService dbService, User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Giá từ', style: TextStyle(color: Colors.grey)),
                Text('${widget.tour.price.toInt()}đ',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final res = await dbService.bookTour(
                  user?.uid ?? 'guest', widget.tour.id);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(res)));
            },
            child: const Text('ĐẶT VÉ NGAY',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
