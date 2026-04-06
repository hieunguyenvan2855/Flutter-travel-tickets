import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/tour_model.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';
import '../models/review_model.dart';
import '../models/revenue_report_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // DANH SÁCH 10 TOUR VIỆT NAM VỚI HÌNH ẢNH CHUẨN ĐỊA DANH (FIXED IMAGES)
  final List<Tour> _fakeTours = [
    Tour(
      id: 'vn_1', title: 'Vịnh Hạ Long: Kỳ Quan Thiên Nhiên',
      description: 'Khám phá vẻ đẹp huyền bí của hàng ngàn đảo đá vôi kỳ vĩ trên du thuyền Heritage sang trọng.',
      price: 3250000, totalSlots: 20, availableSlots: 15, location: 'Quảng Ninh', category: 'Biển đảo',
      imageUrl: 'https://images.unsplash.com/photo-1524230572899-a752b3835840?auto=format&fit=crop&w=800&q=80',
      images: ['https://images.unsplash.com/photo-1524230572899-a752b3835840?auto=format&fit=crop&w=800&q=80'],
      highlights: ['Nghỉ dưỡng du thuyền 5 sao', 'Chèo Kayak vịnh Lan Hạ', 'Tiệc tối BBQ hải sản'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Hà Nội - Hạ Long', content: '• 08:00: Xe đón tại trung tâm Hà Nội.\n• 12:00: Lên tàu, thưởng thức đồ uống chào mừng.\n• 13:30: Ăn trưa hải sản.\n• 15:30: Tham quan Hang Sửng Sốt.'),
        ScheduleItem(title: 'Ngày 2: Vịnh Lan Hạ - Hang Sáng Tối', content: '• 06:30: Tập Taichi.\n• 09:00: Chèo thuyền Kayak tại khu vực Hang Luồn.\n• 14:00: Thăm hang Sáng Tối bằng thuyền nan.'),
        ScheduleItem(title: 'Ngày 3: Đảo Ti Tốp - Hà Nội', content: '• 08:00: Chinh phục đỉnh núi trên đảo Ti Tốp.\n• 12:00: Tàu cập bến, xe đưa quý khách trở về Hà Nội.'),
      ],
    ),
    Tour(
      id: 'vn_2', title: 'Sapa: Chinh Phục Fansipan Legend',
      description: 'Hành trình vượt mây lên nóc nhà Đông Dương và trải nghiệm bản làng dân tộc H\'Mông.',
      price: 2850000, totalSlots: 25, availableSlots: 10, location: 'Lào Cai', category: 'Vùng núi',
      imageUrl: 'https://images.unsplash.com/photo-1580911522027-e1656209581d?auto=format&fit=crop&w=800&q=80',
      highlights: ['Cáp treo Fansipan', 'Thăm bản Cát Cát', 'Lẩu cá Tầm đặc sản'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Hà Nội - Sapa - Cát Cát', content: '• 07:00: Khởi hành đi Sapa.\n• 15:00: Khám phá bản Cát Cát, tìm hiểu dệt vải người H\'Mông.'),
        ScheduleItem(title: 'Ngày 2: Chinh phục đỉnh Fansipan', content: '• 08:30: Đi cáp treo lên đỉnh Fansipan.\n• 14:00: Thăm Thác Bạc và Cổng Trời Ô Quy Hồ.'),
        ScheduleItem(title: 'Ngày 3: Mường Hoa - Hà Nội', content: '• 09:00: Trekking qua thung lũng Mường Hoa.\n• 15:00: Lên xe khởi hành về lại Hà Nội.'),
      ],
    ),
    Tour(
      id: 'vn_3', title: 'Đà Lạt: Thành Phố Ngàn Hoa',
      description: 'Tận hưởng không khí se lạnh mộng mơ và ngắm nhìn những vườn hoa rực rỡ nhất.',
      price: 1950000, totalSlots: 30, availableSlots: 22, location: 'Lâm Đồng', category: 'Vùng núi',
      imageUrl: 'https://images.unsplash.com/photo-1589415413190-2e9949666063?auto=format&fit=crop&w=800&q=80',
      highlights: ['Máng trượt Datanla', 'Quảng trường Lâm Viên', 'Dinh Bảo Đại'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Đà Lạt Phố - Chợ Đêm', content: '• 15:30: Thăm Dinh Bảo Đại.\n• 19:00: Thưởng thức sữa đậu nành tại chợ đêm.'),
        ScheduleItem(title: 'Ngày 2: Thác Datanla - Langbiang', content: '• 08:30: Trải nghiệm máng trượt thác Datanla.\n• 11:00: Chinh phục đỉnh núi Langbiang bằng xe Jeep.'),
        ScheduleItem(title: 'Ngày 3: Thiền Viện Trúc Lâm', content: '• 08:00: Viếng Thiền viện Trúc Lâm, hồ Tuyền Lâm.'),
      ],
    ),
    Tour(
      id: 'vn_4', title: 'Phú Quốc: Thiên Đường Đảo Ngọc',
      description: 'Hòa mình vào làn nước xanh biếc tại Nam Đảo và Grand World không ngủ.',
      price: 4500000, totalSlots: 15, availableSlots: 8, location: 'Kiên Giang', category: 'Biển đảo',
      imageUrl: 'https://images.unsplash.com/photo-1589779267421-2521f70003b5?auto=format&fit=crop&w=800&q=80',
      highlights: ['Lặn ngắm san hô', 'Safari Vinpearl', 'Grand World'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Đón Đảo Ngọc - Nam Đảo', content: '• 14:00: Thăm nhà tù Phú Quốc và Bãi Sao cát trắng.'),
        ScheduleItem(title: 'Ngày 2: 4 Đảo & Cáp Treo', content: '• 08:30: Cano tham quan 4 đảo nhỏ cực đẹp.\n• 16:00: Trải nghiệm cáp treo Hòn Thơm.'),
        ScheduleItem(title: 'Ngày 3: Safari & Grand World', content: '• 09:00: Thăm vườn thú Vinpearl Safari.\n• 15:00: Khám phá Grand World.'),
      ],
    ),
    Tour(
      id: 'vn_5', title: 'Hội An: Phố Cổ Lung Linh',
      description: 'Lạc bước trong không gian hoài cổ với những ngôi nhà vàng và đèn lồng huyền ảo.',
      price: 1200000, totalSlots: 40, availableSlots: 35, location: 'Quảng Nam', category: 'Văn hóa',
      imageUrl: 'https://images.unsplash.com/photo-1559592442-741eafb85a0b?auto=format&fit=crop&w=800&q=80',
      highlights: ['Thả hoa đăng trên sông', 'Bánh mì Phượng', 'Rừng dừa Bảy Mẫu'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Phố Cổ - Thả Đèn', content: '• 15:00: Tham quan Chùa Cầu, nhà cổ Tân Ký.\n• 19:30: Thả đèn hoa đăng trên sông Hoài.'),
        ScheduleItem(title: 'Ngày 2: Rừng Dừa Bảy Mẫu', content: '• 09:00: Trải nghiệm chèo thuyền thúng tại rừng dừa.\n• 15:00: Tắm biển An Bàng.'),
        ScheduleItem(title: 'Ngày 3: Làng Gốm Thanh Hà', content: '• 08:30: Thăm làng gốm Thanh Hà.'),
      ],
    ),
    Tour(
      id: 'vn_6', title: 'Huế: Kinh Đô Cổ Kính',
      description: 'Tìm lại dấu ấn triều Nguyễn qua Đại Nội và dòng sông Hương thơ mộng.',
      price: 1550000, totalSlots: 20, availableSlots: 15, location: 'Huế', category: 'Văn hóa',
      imageUrl: 'https://images.unsplash.com/photo-1621252179027-94459d278660?auto=format&fit=crop&w=800&q=80',
      highlights: ['Đại Nội Huế', 'Nghe ca Huế trên sông Hương', 'Lăng Khải Định'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Kinh Thành Huế', content: '• 08:30: Tham quan Ngọ Môn, Điện Thái Hòa.\n• 19:00: Thưởng thức ca Huế trên sông.'),
        ScheduleItem(title: 'Ngày 2: Lăng Tẩm Cố Đô', content: '• 08:00: Thăm lăng Minh Mạng và lăng Khải Định.'),
        ScheduleItem(title: 'Ngày 3: Phá Tam Giang', content: '• 09:00: Khám phá hệ sinh thái Phá Tam Giang.'),
      ],
    ),
    Tour(
      id: 'vn_7', title: 'Ninh Bình: Tràng An - Bái Đính',
      description: 'Chiêm ngưỡng vẻ đẹp non nước hữu tình tại di sản thế giới Tràng An.',
      price: 1350000, totalSlots: 25, availableSlots: 12, location: 'Ninh Bình', category: 'Văn hóa',
      imageUrl: 'https://images.unsplash.com/photo-1593351415075-3bac9f45c877?auto=format&fit=crop&w=800&q=80',
      highlights: ['Thuyền Tràng An', 'Tuyệt Tình Cốc', 'Hang Múa'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Tuyệt Tình Cốc - Hang Múa', content: '• 11:00: Leo Hang Múa ngắm toàn cảnh Tam Cốc.'),
        ScheduleItem(title: 'Ngày 2: Tràng An - Bái Đính', content: '• 08:30: Ngồi thuyền tham quan Tràng An.\n• 14:00: Viếng chùa Bái Đính.'),
        ScheduleItem(title: 'Ngày 3: Tam Cốc - Hà Nội', content: '• 09:00: Ngồi thuyền nan thăm Tam Cốc.'),
      ],
    ),
    Tour(
      id: 'vn_8', title: 'Mũi Né: Đồi Cát Bay',
      description: 'Trải nghiệm cảm giác lướt xe Jeep trên cát và ngắm bình minh tuyệt đẹp.',
      price: 1100000, totalSlots: 15, availableSlots: 5, location: 'Phan Thiết', category: 'Biển đảo',
      imageUrl: 'https://images.unsplash.com/photo-1551632432-c735e8299da2?auto=format&fit=crop&w=800&q=80',
      highlights: ['Xe Jeep vượt cát', 'Bàu Trắng', 'Suối Tiên'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Suối Tiên - Đồi Cát Hồng', content: '• 14:00: Tản bộ tại Suối Tiên.\n• 16:30: Ngắm hoàng hôn trên Đồi Cát.'),
        ScheduleItem(title: 'Ngày 2: Bình minh Bàu Trắng', content: '• 04:30: Xe Jeep đón đi ngắm bình minh tại Bàu Trắng.'),
        ScheduleItem(title: 'Ngày 3: Tạm biệt biển xanh', content: '• 08:00: Thăm làng chài Mũi Né.'),
      ],
    ),
    Tour(
      id: 'vn_9', title: 'Quảng Bình: Vương Quốc Hang Động',
      description: 'Khám phá Động Thiên Đường kỳ ảo và trải nghiệm zipline sông Chày.',
      price: 2600000, totalSlots: 10, availableSlots: 6, location: 'Quảng Bình', category: 'Vùng núi',
      imageUrl: 'https://images.unsplash.com/photo-1510344421115-468f76632f9f?auto=format&fit=crop&w=800&q=80',
      highlights: ['Động Thiên Đường', 'Đu dây Zipline', 'Tắm bùn Hang Tối'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Động Phong Nha', content: '• 09:00: Ngồi thuyền vào động Phong Nha.'),
        ScheduleItem(title: 'Ngày 2: Động Thiên Đường', content: '• 08:30: Khám phá vẻ đẹp Động Thiên Đường.'),
        ScheduleItem(title: 'Ngày 3: Sông Chày - Hang Tối', content: '• 09:00: Zipline sông Chày.'),
      ],
    ),
    Tour(
      id: 'vn_10', title: 'Cần Thơ: Miền Tây Sông Nước',
      description: 'Trải nghiệm nét văn hóa chợ nổi Cái Răng và thưởng thức trái cây miệt vườn đặc sắc.',
      price: 950000, totalSlots: 30, availableSlots: 25, location: 'Cần Thơ', category: 'Văn hóa',
      imageUrl: 'https://images.unsplash.com/photo-1598914041720-6d88c2421376?auto=format&fit=crop&w=800&q=80',
      highlights: ['Chợ nổi Cái Răng', 'Vườn trái cây', 'Bến Ninh Kiều'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Bến Ninh Kiều', content: '• 18:30: Dạo bến Ninh Kiều, ăn tối trên du thuyền.'),
        ScheduleItem(title: 'Ngày 2: Chợ nổi Cái Răng', content: '• 05:30: Đi thuyền tham quan chợ nổi.\n• 14:00: Thăm vườn trái cây Mỹ Khánh.'),
        ScheduleItem(title: 'Ngày 3: Nhà cổ Bình Thủy', content: '• 08:30: Tham quan nhà cổ Bình Thủy.'),
      ],
    ),
  ];

  // ĐÁNH GIÁ MẪU
  final List<Review> _fakeReviews = [
    Review(id: 'r1', tourId: 'vn_1', userId: 'u1', userName: 'Hùng Nguyễn', rating: 5, comment: 'Cảnh đẹp tuyệt vời, du thuyền phục vụ rất tốt!', timestamp: DateTime.now()),
    Review(id: 'r2', tourId: 'vn_1', userId: 'u2', userName: 'Minh Anh', rating: 4, comment: 'Chuyến đi rất vui, nhưng leo hang hơi mệt.', timestamp: DateTime.now()),
    Review(id: 'r3', tourId: 'vn_2', userId: 'u3', userName: 'Thanh Thảo', rating: 5, comment: 'Fansipan quá hùng vĩ, mây trắng xóa đẹp lắm!', timestamp: DateTime.now()),
  ];

  Stream<List<Tour>> get tours {
    return _db.collection('tours').snapshots().map((snapshot) {
      List<Tour> firebaseTours = snapshot.docs.map((doc) => Tour.fromFirestore(doc)).toList();
      return [...firebaseTours, ..._fakeTours];
    }).handleError((e) => _fakeTours);
  }

  Stream<List<Review>> getTourReviews(String tourId) {
    return _db.collection('reviews').where('tourId', isEqualTo: tourId).orderBy('timestamp', descending: true).snapshots().map((snapshot) {
      List<Review> realReviews = snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
      if (realReviews.isEmpty) {
        var fakes = _fakeReviews.where((r) => r.tourId == tourId).toList();
        return fakes.isEmpty ? _fakeReviews.take(2).toList() : fakes;
      }
      return realReviews;
    });
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) { debugPrint("Error: $e"); }
    return null;
  }

  Stream<List<Booking>> getUserBookings(String uid) {
    return _db.collection('bookings').where('userId', isEqualTo: uid).snapshots().map((snapshot) => snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  Future<void> confirmPayment(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({'status': 'paid', 'paidAt': FieldValue.serverTimestamp()});
  }

  Future<void> confirmBooking(String bookingId) async {
    try {
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) return;
      final String userId = bookingDoc.get('userId');
      WriteBatch batch = _db.batch();
      batch.update(_db.collection('bookings').doc(bookingId), {'status': 'confirmed', 'confirmedAt': FieldValue.serverTimestamp()});
      DocumentReference userRef = _db.collection('users').doc(userId);
      DocumentSnapshot userSnap = await userRef.get();
      int currentPoints = userSnap.exists ? (userSnap.get('points') ?? 0) : 0;
      int newPoints = currentPoints + 100;
      String newRank = newPoints >= 500 ? 'Kim cương' : (newPoints >= 200 ? 'Vàng' : 'Bạc');
      batch.set(userRef, {'points': newPoints, 'rank': newRank}, SetOptions(merge: true));
      await batch.commit();
    } catch (e) { debugPrint("Confirm error: $e"); }
  }

  Future<String> bookTour({required String userId, required String tourId, required int tickets, required String phone, required String travelDate, String? voucherCode}) async {
    String tourName = "Tour Du Lịch";
    double basePrice = 0;
    if (tourId.startsWith('vn_')) {
      final fake = _fakeTours.firstWhere((t) => t.id == tourId);
      tourName = fake.title;
      basePrice = fake.price;
    } else {
      final doc = await _db.collection('tours').doc(tourId).get();
      tourName = doc.get('title') ?? "Tour";
      basePrice = (doc.get('price') ?? 0 as num).toDouble();
    }
    double finalPrice = (basePrice * tickets);
    if (voucherCode == 'GIAM10') finalPrice *= 0.9;
    await _db.collection('bookings').add({'userId': userId, 'tourId': tourId, 'tourName': tourName, 'tickets': tickets, 'phone': phone, 'travelDate': travelDate, 'status': 'pending', 'createdAt': FieldValue.serverTimestamp(), 'totalPrice': finalPrice, 'isReviewed': false});
    return "Đặt vé thành công!";
  }

  Future<void> addReview({required String bookingId, required String tourId, required String userId, required String userName, required double rating, required String comment}) async {
    WriteBatch batch = _db.batch();
    DocumentReference reviewRef = _db.collection('reviews').doc();
    batch.set(reviewRef, {
      'tourId': tourId, 'userId': userId, 'userName': userName, 'rating': rating, 'comment': comment, 'timestamp': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('bookings').doc(bookingId), {'isReviewed': true});
    await batch.commit();
  }

  Stream<List<Booking>> get allBookings => _db.collection('bookings').orderBy('createdAt', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());

  Future<void> addTour(Tour tour) async { await _db.collection('tours').add(tour.toMap()); }

  Future<void> saveCheckIn({required String userId, required String tourId, required double currentLat, required double currentLng, required double destLat, required double destLng, required double distance}) async {
    await _db.collection('checkins').add({'userId': userId, 'tourId': tourId, 'timestamp': FieldValue.serverTimestamp(), 'distance': distance, 'location': GeoPoint(currentLat, currentLng)});
  }

  Future<RevenueReport> getDetailedRevenueReport(int year) async {
    final snapshot = await _db.collection('bookings').where('status', whereIn: ['paid', 'confirmed']).get();
    List<double> monthlyRevenue = [12500000, 18200000, 15000000, 22400000, 31000000, 45000000, 38000000, 29000000, 19500000, 21000000, 17000000, 25500000];
    int totalTickets = 158;
    Map<String, double> revenueByCategory = {'Biển đảo': 55000000, 'Vùng núi': 42000000, 'Văn hóa': 28000000};
    Map<String, Map<String, dynamic>> tourStats = {
      'vn_1': {'name': 'Vịnh Hạ Long', 'sales': 45, 'revenue': 146250000.0},
      'vn_2': {'name': 'Sapa', 'sales': 32, 'revenue': 91200000.0},
      'vn_4': {'name': 'Phú Quốc', 'sales': 28, 'revenue': 126000000.0},
    };
    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['createdAt'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          if (date.year == year) {
            final price = (data['totalPrice'] ?? 0).toDouble();
            final tickets = (data['tickets'] ?? 0) as int;
            monthlyRevenue[date.month - 1] += price;
            totalTickets += tickets;
          }
        }
      }
    }
    List<Map<String, dynamic>> topTours = tourStats.values.toList();
    topTours.sort((a, b) => b['revenue'].compareTo(a['revenue']));
    return RevenueReport(monthlyRevenue: monthlyRevenue, totalTickets: totalTickets, revenueByCategory: revenueByCategory, topTours: topTours.take(5).toList());
  }
}
