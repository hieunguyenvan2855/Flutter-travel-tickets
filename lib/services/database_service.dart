import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/tour_model.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';
import '../models/review_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<Tour> _fakeTours = [
    Tour(
      id: 'fake_1',
      title: 'Vịnh Hạ Long: Du Thuyền Heritage 5 Sao',
      description: 'Khám phá di sản thiên nhiên thế giới với hành trình trên du thuyền sang trọng phong cách Indochine.',
      price: 3250000,
      totalSlots: 20,
      availableSlots: 15,
      location: 'Quảng Ninh',
      category: 'Biển đảo',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f0/Ha_Long_Bay_Panorama.jpg/800px-Ha_Long_Bay_Panorama.jpg',
      images: [
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f0/Ha_Long_Bay_Panorama.jpg/800px-Ha_Long_Bay_Panorama.jpg',
        'https://upload.wikimedia.org/wikipedia/commons/b/bd/Ha_long_bay_3.jpg',
      ],
      highlights: ['Nghỉ dưỡng cabin hạng sang', 'Chèo thuyền Kayak vịnh Lan Hạ', 'Tiệc tối BBQ hải sản'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Hà Nội - Tuần Châu - Vịnh Hạ Long', content: '• 08:30: Xe đón tại Hà Nội khởi hành đi Hạ Long.\n• 12:00: Làm thủ tục lên tàu, thưởng thức đồ uống chào mừng.\n• 13:30: Ăn trưa buffet trong khi du thuyền di chuyển qua các đảo đá vôi.\n• 15:30: Tham quan Hang Sửng Sốt - hang động đẹp nhất vịnh.\n• 19:30: Bữa tối hải sản và câu mực đêm.'),
        ScheduleItem(title: 'Ngày 2: Hang Sáng Tối - Hà Nội', content: '• 06:15: Tập Thái Cực Quyền đón bình minh.\n• 07:30: Thăm hang Sáng Tối bằng thuyền nan do dân địa phương chèo.\n• 09:30: Trả phòng và ăn trưa sớm (Brunch).\n• 12:00: Tàu về bến, xe đưa quý khách về lại Hà Nội.'),
      ],
    ),
    Tour(
      id: 'fake_2',
      title: 'Sapa: Chinh Phục Fansipan Legend',
      description: 'Hành trình vượt mây lên đỉnh cao 3.143m, khám phá bản làng và nét văn hóa độc đáo của người dân vùng cao.',
      price: 2850000,
      totalSlots: 25,
      availableSlots: 10,
      location: 'Lào Cai',
      category: 'Vùng núi',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/03/Sapa_Terraced_Rice_Fields.jpg',
      images: ['https://upload.wikimedia.org/wikipedia/commons/0/03/Sapa_Terraced_Rice_Fields.jpg'],
      highlights: ['Vé cáp treo Fansipan Legend', 'Thăm bản Cát Cát thơ mộng', 'Đèo Ô Quy Hồ hùng vĩ'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Hà Nội - Sapa - Bản Cát Cát', content: '• 07:00: Xe khởi hành đi Sapa.\n• 13:00: Ăn trưa đặc sản vùng cao.\n• 15:00: Đi bộ tham quan bản Cát Cát, tìm hiểu dệt vải H\'Mông.\n• 19:00: Ăn tối đồ nướng, tự do dạo phố đêm.'),
        ScheduleItem(title: 'Ngày 2: Fansipan - Đỉnh Cao Đại Ngàn', content: '• 08:00: Đi cáp treo chinh phục đỉnh Fansipan.\n• 10:30: Check-in cột mốc 3.143m và quần thể tâm linh.\n• 12:30: Ăn trưa Buffet tại ga cáp treo.\n• 15:00: Thăm đỉnh đèo Ô Quy Hồ trước khi về.'),
      ],
    ),
    Tour(
      id: 'fake_3',
      title: 'Đà Lạt: Thành Phố Ngàn Hoa & Tình Yêu',
      description: 'Tận hưởng không khí se lạnh mộng mơ, ngắm đồi thông và những vườn hoa rực rỡ giữa lòng Tây Nguyên.',
      price: 1950000,
      totalSlots: 30,
      availableSlots: 22,
      location: 'Lâm Đồng',
      category: 'Vùng núi',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Dalat_Railway_Station.jpg/800px-Dalat_Railway_Station.jpg',
      images: ['https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Dalat_Railway_Station.jpg/800px-Dalat_Railway_Station.jpg'],
      highlights: ['Máng trượt Datanla dài nhất ĐNA', 'Check-in Quảng trường Lâm Viên', 'Thưởng thức kem bơ'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Đà Lạt Phố - Chợ Đêm', content: '• 09:00: Thăm Dinh Bảo Đại, Nhà thờ Con Gà.\n• 14:00: Vui chơi tại ga Đà Lạt cổ.\n• 19:00: Dạo chợ đêm, ăn bánh tráng nướng.'),
        ScheduleItem(title: 'Ngày 2: Thiên nhiên & Thác Nước', content: '• 08:00: Viếng Thiền viện Trúc Lâm, ngắm hồ Tuyền Lâm.\n• 10:00: Trải nghiệm máng trượt thác Datanla.\n• 15:00: Thăm vườn hoa Cẩm Tú Cầu.'),
      ],
    ),
  ];

  Stream<List<Tour>> get tours {
    return _db.collection('tours').snapshots().map((snapshot) {
      List<Tour> firebaseTours = snapshot.docs.map((doc) => Tour.fromFirestore(doc)).toList();
      return [...firebaseTours, ..._fakeTours];
    }).handleError((e) {
      return _fakeTours;
    });
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get().timeout(const Duration(seconds: 5));
      if (doc.exists) return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint("User data error: $e");
    }
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
      int currentPoints = 0;
      if (userSnap.exists) {
        try { currentPoints = userSnap.get('points') ?? 0; } catch (e) {}
      }
      int newPoints = currentPoints + 100;
      String newRank = newPoints >= 500 ? 'Kim cương' : (newPoints >= 200 ? 'Vàng' : 'Bạc');
      batch.set(userRef, {'points': newPoints, 'rank': newRank}, SetOptions(merge: true));
      await batch.commit();
    } catch (e) {
      debugPrint("Confirm error: $e");
    }
  }

  Future<String> bookTour({required String userId, required String tourId, required int tickets, required String phone, required String travelDate, String? voucherCode}) async {
    String tourName = "Tour Du Lịch";
    double basePrice = 0;
    if (tourId.startsWith('fake_')) {
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

  Future<void> saveCheckIn({required String userId, required String tourId, required double currentLat, required double currentLng, required double destLat, required double destLng, required double distance}) async {
    await _db.collection('checkins').add({'userId': userId, 'tourId': tourId, 'distance': distance, 'timestamp': FieldValue.serverTimestamp(), 'location': GeoPoint(currentLat, currentLng)});
  }

  Stream<List<Review>> getTourReviews(String tourId) {
    return _db.collection('reviews').where('tourId', isEqualTo: tourId).orderBy('timestamp', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList());
  }

  Stream<List<Booking>> get allBookings => _db.collection('bookings').orderBy('createdAt', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());

  Future<void> addTour(Tour tour) async {
    await _db.collection('tours').add(tour.toMap());
  }
}
