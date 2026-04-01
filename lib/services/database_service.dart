import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tour_model.dart';
import '../models/booking_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String TOUR_CACHE_KEY = 'tours_cache';

  final List<Tour> _fakeTours = [
    Tour(
      id: 'fake_1',
      title: 'Hạ Long: Du Thuyền 5 Sao Heritage',
      description: 'Trải nghiệm đẳng cấp trên du thuyền phong cách Đông Dương.',
      price: 3850000,
      totalSlots: 15,
      availableSlots: 12,
      location: 'Quảng Ninh',
      category: 'Biển đảo',
      imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?q=80&w=1200',
      highlights: ['Du thuyền hạng sang', 'Thăm hang Sửng Sốt'],
      scheduleItems: [
        ScheduleItem(title: 'Ngày 1: Hà Nội - Tuần Châu', content: 'Đón khách, lên tàu ăn trưa.'),
        ScheduleItem(title: 'Ngày 2: Vịnh Lan Hạ', content: 'Thăm hang Sáng Tối.'),
      ],
    ),
  ];

  Stream<List<Tour>> get tours {
    return _db.collection('tours').snapshots().asyncMap((snapshot) async {
      List<Tour> firebaseTours = snapshot.docs.map((doc) => Tour.fromFirestore(doc)).toList();
      return [...firebaseTours, ..._fakeTours];
    });
  }

  Stream<List<Booking>> getUserBookings(String uid) {
    return _db.collection('bookings')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  Future<void> confirmPayment(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  // FIXED: Added missing confirmBooking method for Admin
  Future<void> confirmBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': 'confirmed',
      'confirmedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> bookTour(String userId, String tourId, {String? voucherCode}) async {
    String tourName = "Tour Du Lịch";
    double basePrice = 0;

    if (tourId.startsWith('fake_')) {
      final fake = _fakeTours.firstWhere((t) => t.id == tourId);
      tourName = fake.title;
      basePrice = fake.price;
    } else {
      final doc = await _db.collection('tours').doc(tourId).get();
      tourName = doc.get('title') ?? "Tour không tên";
      basePrice = (doc.get('price') ?? 0 as num).toDouble();
    }

    double finalPrice = basePrice;
    if (voucherCode == 'GIAM10') finalPrice *= 0.9;

    await _db.collection('bookings').add({
      'userId': userId,
      'tourId': tourId,
      'tourName': tourName,
      'tickets': 1,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'totalPrice': finalPrice,
      'isReviewed': false,
    });
    
    return "Đặt vé thành công!";
  }

  // --- ADMIN OPERATIONS ---
  Stream<List<Booking>> get allBookings {
    return _db.collection('bookings').snapshots().map((snapshot) => snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  Future<void> addTour(Tour tour) async {
    await _db.collection('tours').add(tour.toMap());
  }

  Future<void> saveCheckIn({
    required String userId,
    required String tourId,
    required double currentLat,
    required double currentLng,
    required double destLat,
    required double destLng,
    required double distance,
  }) async {
    await _db.collection('checkins').add({
      'userId': userId,
      'tourId': tourId,
      'timestamp': FieldValue.serverTimestamp(),
      'distance': distance,
    });
  }
}
