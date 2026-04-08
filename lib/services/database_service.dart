import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/tour_model.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';
import '../models/review_model.dart';

// --- ĐỊNH NGHĨA CLASS BÁO CÁO DOANH THU ---
class RevenueReport {
  final List<double> monthlyRevenue;
  final Map<String, double> revenueByCategory;
  final List<Map<String, dynamic>> topTours;
  final int totalTickets;
  final double averageValue;
  RevenueReport({
    required this.monthlyRevenue, 
    required this.revenueByCategory, 
    required this.topTours, 
    required this.totalTickets, 
    required this.averageValue
  });
}

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- KHO 10 TOUR VIỆT NAM VIP ---
  final List<Tour> _fakeTours = [
    Tour(
      id: 'vn_1', title: 'Vịnh Hạ Long: Du Thuyền Heritage 5 Sao',
      description: 'Trải nghiệm du thuyền sang trọng phong cách Indochine giữa lòng kỳ quan thiên nhiên thế giới.',
      price: 3250000, totalSlots: 20, availableSlots: 15, location: 'Quảng Ninh', category: 'Biển đảo',
      geoPoint: const GeoPoint(20.9101, 107.1839),
      imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?q=80&w=1200',
      highlights: ['Nghỉ dưỡng cabin ban công', 'Chèo Kayak Hang Luồn', 'Tiệc tối BBQ hải sản'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Hà Nội - Hạ Long', content: '• 08:30 Đón khách tại Hà Nội. 12:00 Lên tàu, ăn trưa buffet. 15:30 Thăm hang Sửng Sốt.'),
        ScheduleItem(title: 'Ngày 2: Lan Hạ - Hà Nội', content: '• 06:00 Tập Tai Chi đón bình minh. 08:30 Thăm hang Sáng Tối bằng thuyền nan.'),
      ],
    ),
    Tour(
      id: 'vn_2', title: 'Sapa: Chinh Phục Fansipan Legend',
      description: 'Hành trình vượt mây lên nóc nhà Đông Dương và trải nghiệm văn hóa bản làng dân tộc độc đáo.',
      price: 2850000, totalSlots: 25, availableSlots: 10, location: 'Lào Cai', category: 'Vùng núi',
      geoPoint: const GeoPoint(22.3364, 103.8438),
      imageUrl: 'https://images.unsplash.com/photo-1599342718782-93809033322e?q=80&w=1200',
      highlights: ['Vé cáp treo Fansipan', 'Thăm bản Cát Cát', 'Lẩu cá Tầm'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Hà Nội - Sapa', content: '• 07:00 Khởi hành đi Sapa. 14:00 Thăm bản Cát Cát.'),
      ],
    ),
    Tour(
      id: 'vn_3', title: 'Đà Lạt: Thành Phố Ngàn Hoa & Tình Yêu',
      description: 'Tận hưởng không khí se lạnh mộng mơ và ngắm nhìn những vườn hoa rực rỡ nhất Việt Nam.',
      price: 1950000, totalSlots: 30, availableSlots: 22, location: 'Lâm Đồng', category: 'Vùng núi',
      geoPoint: const GeoPoint(11.9465, 108.4419),
      imageUrl: 'https://images.unsplash.com/photo-1589415413190-2e9949666063?q=80&w=1200',
      highlights: ['Quảng trường Lâm Viên', 'Thác Datanla', 'Vườn hoa TP'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Đà Lạt Phố', content: '• 09:00 Dinh Bảo Đại. 14:00 Ga Đà Lạt cổ.'),
      ],
    ),
    Tour(
      id: 'vn_4', title: 'Phú Quốc: Thiên Đường Đảo Ngọc',
      description: 'Hòa mình vào làn nước xanh ngắt, lặn ngắm san hô và vui chơi tại Grand World.',
      price: 4500000, totalSlots: 15, availableSlots: 8, location: 'Kiên Giang', category: 'Biển đảo',
      geoPoint: const GeoPoint(10.2289, 103.9036),
      imageUrl: 'https://images.unsplash.com/photo-1581390129939-946f9a890a7f?q=80&w=1200',
      highlights: ['Lặn ngắm san hô', 'Safari Phú Quốc', 'Grand World'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Nam Đảo', content: '• 08:30 Thăm Bãi Sao. 14:00 Cano đi 4 đảo nhỏ.'),
      ],
    ),
    Tour(
      id: 'vn_5', title: 'Hội An: Phố Cổ Hoài Niệm & Lung Linh',
      description: 'Lạc bước trong không gian xưa cũ với những ngôi nhà vàng và ánh đèn lồng huyền ảo.',
      price: 1200000, totalSlots: 40, availableSlots: 35, location: 'Quảng Nam', category: 'Văn hóa',
      geoPoint: const GeoPoint(15.8801, 108.3384),
      imageUrl: 'https://images.unsplash.com/photo-1599147502213-90998632616a?q=80&w=1200',
      highlights: ['Thả hoa đăng', 'Bánh mì Phượng', 'Thánh địa Mỹ Sơn'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Di Sản Hội An', content: '15:00 Chùa Cầu. 19:30 Thả hoa đăng sông Hoài.'),
      ],
    ),
  ];

  // --- REVIEW MẪU ---
  final List<Review> _fakeReviews = [
    Review(id: 'r1', tourId: 'vn_1', userId: 'u1', userName: 'Hoàng Minh', rating: 5, comment: 'Du thuyền Heritage quá đẳng cấp, phục vụ 5 sao thực sự!', timestamp: DateTime.now()),
    Review(id: 'r2', tourId: 'vn_2', userId: 'u2', userName: 'Thanh Trúc', rating: 4.5, comment: 'Fansipan mùa này săn mây cực đỉnh luôn mọi người ơi.', timestamp: DateTime.now()),
  ];

  // --- PHẦN DOANH THU CHI TIẾT (ĐÃ SỬA LẠI CHUYÊN NGHIỆP) ---
  Future<RevenueReport> getDetailedRevenueReport(int year) async {
    // 1. Doanh thu biến thiên theo tháng (tháng hè và lễ Tết cao hơn)
    List<double> monthly = [
      42000000, 38000000, 51000000, 78000000, 65000000, 92000000, 
      98000000, 85000000, 45000000, 32000000, 48000000, 72000000
    ];

    // 2. Doanh thu theo danh mục tour
    Map<String, double> byCategory = {
      'Biển đảo': 350000000,
      'Vùng núi': 210000000,
      'Văn hóa': 125000000,
    };

    // 3. Danh sách Top Tour bán chạy
    List<Map<String, dynamic>> topTours = [
      {'name': 'Vịnh Hạ Long Cruise', 'revenue': 185000000.0, 'sales': 57},
      {'name': 'Phú Quốc 4 Đảo', 'revenue': 142000000.0, 'sales': 32},
      {'name': 'Sapa Fansipan', 'revenue': 98000000.0, 'sales': 34},
    ];

    int totalTickets = 123;
    double totalRevenue = monthly.reduce((a, b) => a + b);

    // 4. Cộng dồn dữ liệu thật từ Firestore (nếu có)
    try {
      final snapshot = await _db.collection('bookings')
          .where('status', whereIn: ['paid', 'confirmed', 'completed']).get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          DateTime date = (data['createdAt'] as Timestamp).toDate();
          if (date.year == year) {
            double price = (data['totalPrice'] as num).toDouble();
            int tickets = data['tickets'] as int? ?? 1;
            monthly[date.month - 1] += price;
            totalTickets += tickets;
            totalRevenue += price;
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi báo cáo thực tế: $e");
    }

    return RevenueReport(
      monthlyRevenue: monthly,
      revenueByCategory: byCategory,
      topTours: topTours,
      totalTickets: totalTickets,
      averageValue: totalRevenue / (totalTickets == 0 ? 1 : totalTickets),
    );
  }

  Stream<List<Tour>> get tours {
    return _db.collection('tours').snapshots().map((snapshot) {
      List<Tour> firebaseTours = snapshot.docs.map((doc) => Tour.fromFirestore(doc)).toList();
      List<Tour> result = [...firebaseTours];
      for (var fake in _fakeTours) {
        if (!firebaseTours.any((t) => t.id == fake.id)) result.add(fake);
      }
      return result;
    }).handleError((e) => _fakeTours);
  }

  Stream<List<Review>> getTourReviews(String tourId) {
    return _db.collection('reviews').where('tourId', isEqualTo: tourId).snapshots().map((snapshot) {
      List<Review> realReviews = snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
      return [...realReviews, ..._fakeReviews.where((r) => r.tourId == tourId)];
    });
  }

  Future<void> updateTour(String id, Map<String, dynamic> data) async => await _db.collection('tours').doc(id).set(data, SetOptions(merge: true));
  Future<void> addTour(Tour tour) async => await _db.collection('tours').add(tour.toMap());
  
  Future<UserModel?> getUserData(String uid) async {
    final d = await _db.collection('users').doc(uid).get();
    return d.exists ? UserModel.fromMap(d.data()!) : null;
  }

  Stream<List<Booking>> getUserBookings(String uid) => _db.collection('bookings').where('userId', isEqualTo: uid).snapshots().map((s) => s.docs.map((d) => Booking.fromFirestore(d)).toList());
  Stream<List<Booking>> get allBookings => _db.collection('bookings').orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map((d) => Booking.fromFirestore(d)).toList());
  
  Future<void> confirmPayment(String bookingId) async => await _db.collection('bookings').doc(bookingId).update({'status': 'paid', 'paidAt': FieldValue.serverTimestamp()});
  
  Future<void> confirmBooking(String bookingId) async {
    final b = await _db.collection('bookings').doc(bookingId).get();
    final uid = b.get('userId');
    WriteBatch batch = _db.batch();
    batch.update(_db.collection('bookings').doc(bookingId), {'status': 'confirmed', 'confirmedAt': FieldValue.serverTimestamp()});
    DocumentSnapshot u = await _db.collection('users').doc(uid).get();
    int pts = u.exists ? (u.get('points') ?? 0) : 0;
    batch.set(_db.collection('users').doc(uid), {'points': pts + 100, 'rank': pts + 100 >= 500 ? 'Kim cương' : (pts + 100 >= 200 ? 'Vàng' : 'Bạc')}, SetOptions(merge: true));
    await batch.commit();
  }

  Future<String> bookTour({required String userId, required String tourId, required int tickets, required String phone, required String travelDate, String? voucherCode}) async {
    String name = "Tour Chuyến Đi"; 
    try { name = _fakeTours.firstWhere((t) => t.id == tourId).title; } catch(e) {}
    await _db.collection('bookings').add({'userId': userId, 'tourId': tourId, 'tourName': name, 'tickets': tickets, 'phone': phone, 'travelDate': travelDate, 'status': 'pending', 'createdAt': FieldValue.serverTimestamp(), 'totalPrice': 3000000.0 * tickets, 'isReviewed': false});
    return "Đặt vé thành công!";
  }
}
