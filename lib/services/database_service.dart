import 'package:cloud_firestore/cloud_firestore.dart';
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
      geoPoint: const GeoPoint(20.9101, 107.1839),
      imageUrl:
          'https://images.unsplash.com/photo-1528127269322-539801943592?q=80&w=1200',
      highlights: ['Du thuyền hạng sang', 'Thăm hang Sửng Sốt'],
      scheduleItems: [
        ScheduleItem(
            title: 'Ngày 1: Hà Nội - Tuần Châu - Vịnh Lan Hạ',
            content:
                '12:00: Làm thủ tục lên tàu.\n13:30: Ăn trưa tại nhà hàng.\n15:00: Thăm quan Trà Báu, chèo thuyền Kayak.\n18:00: Tiệc trà chiều ngắm hoàng hôn.'),
        ScheduleItem(
            title: 'Ngày 2: Hang Sáng Tối - Hà Nội',
            content:
                '06:30: Tập Thái Cực Quyền.\n07:30: Thăm hang Sáng Tối bằng thuyền nan.\n10:00: Thưởng thức bữa trưa sớm trước khi về bến.'),
      ],
    ),
    Tour(
      id: 'fake_usa',
      title: 'Liên Tuyến Đông - Tây Hoa Kỳ',
      description:
          'Hành trình khám phá các thành phố biểu tượng của nước Mỹ: New York, Philadelphia, Washington DC, Las Vegas, Los Angeles.',
      price: 97900000,
      totalSlots: 10,
      availableSlots: 5,
      location: 'Hoa Kỳ',
      geoPoint: const GeoPoint(37.7749, -122.4194),
      imageUrl:
          'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?q=80&w=1200',
      highlights: [
        'Trải nghiệm Show thực cảnh',
        'Thăm Tòa Nhà Quốc Hội Mỹ',
        'Khám phá Grand Canyon'
      ],
      scheduleItems: [
        ScheduleItem(
            title: 'Ngày 1: Tp. Hồ Chí Minh -> New York',
            content:
                'Ăn theo tiêu chuẩn trên máy bay. Làm thủ tục nhập cảnh Mỹ.'),
        ScheduleItem(
            title: 'Ngày 2: New York',
            content:
                'Tham quan Tượng Nữ Thần Tự Do, Quảng trường Thời Đại (Times Square). Ăn trưa, tối tại nhà hàng.'),
        ScheduleItem(
            title: 'Ngày 3: New York - Philadelphia - Washington DC',
            content:
                'Tham quan Chuông Tự Do, Xưởng đúc tiền. Di chuyển về thủ đô Washington DC.'),
        ScheduleItem(
            title: 'Ngày 4: Thủ đô Washington -> Los Angeles',
            content:
                'Thăm Nhà Trắng (White House), Đài tưởng niệm Lincoln. Bay sang Los Angeles.'),
        ScheduleItem(
            title: 'Ngày 5: Las Vegas - Grand Canyon',
            content:
                'Khám phá đại vực Grand Canyon hùng vĩ. Trải nghiệm casino tại Las Vegas.'),
        ScheduleItem(
            title: 'Ngày 6: Las Vegas - Los Angeles - Quận Cam',
            content: 'Tham quan Little Saigon. Ăn sáng, trưa, tối đầy đủ.'),
        ScheduleItem(
            title: 'Ngày 7: Los Angeles - San Diego - Los Angeles',
            content: 'Tham quan hạm đội Thái Bình Dương, công viên Balboa.'),
        ScheduleItem(
            title: 'Ngày 8: Los Angeles - Hollywood -> Tp. Hồ Chí Minh',
            content:
                'Tham quan Đại lộ Danh vọng, Nhà hát Dolby. Ra sân bay về Việt Nam.'),
      ],
    ),
  ];

  Stream<List<Tour>> get tours {
    return _db.collection('tours').snapshots().asyncMap((snapshot) async {
      List<Tour> firebaseTours =
          snapshot.docs.map((doc) => Tour.fromFirestore(doc)).toList();
      return [...firebaseTours, ..._fakeTours];
    });
  }

  Stream<List<Booking>> get allBookings {
    return _db
        .collection('bookings')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  Future<void> confirmBooking(String bookingId) async {
    await _db
        .collection('bookings')
        .doc(bookingId)
        .update({'status': 'confirmed'});
  }

  Future<String> bookTour(String userId, String tourId,
      {String? voucherCode}) async {
    if (tourId.startsWith('fake_')) return "Đặt vé tour mẫu thành công!";
    DocumentReference tourRef = _db.collection('tours').doc(tourId);
    DocumentReference bookingRef = _db.collection('bookings').doc();
    return _db.runTransaction((transaction) async {
      DocumentSnapshot tourSnapshot = await transaction.get(tourRef);
      int availableSlots = tourSnapshot.get('availableSlots');
      double basePrice = (tourSnapshot.get('price') as num).toDouble();
      if (availableSlots > 0) {
        double finalPrice = basePrice;
        if (voucherCode == 'GIAM10') finalPrice = basePrice * 0.9;
        transaction.set(bookingRef, {
          'userId': userId,
          'tourId': tourId,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
          'totalPrice': finalPrice,
          'voucherUsed': voucherCode ?? 'none',
        });
        transaction.update(tourRef, {'availableSlots': availableSlots - 1});
        return "Đặt vé thành công! Tổng tiền: $finalPriceđ";
      } else {
        throw Exception("Hết chỗ!");
      }
    });
  }

  Future<void> addTour(Tour tour) async {
    await _db.collection('tours').add(tour.toMap());
  }

  /// Lưu check-in GPS vào Firebase
  Future<void> saveCheckIn({
    required String userId,
    required String tourId,
    required double currentLat,
    required double currentLng,
    required double destLat,
    required double destLng,
    required double distance,
  }) async {
    try {
      // Lấy booking ID từ user và tour để liên kết check-in
      QuerySnapshot bookingSnapshot = await _db
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('tourId', isEqualTo: tourId)
          .limit(1)
          .get();

      String bookingId = bookingSnapshot.docs.isNotEmpty
          ? bookingSnapshot.docs.first.id
          : 'unknown';

      // Lưu check-in record vào collection
      await _db.collection('check_ins').add({
        'userId': userId,
        'tourId': tourId,
        'bookingId': bookingId,
        'checkInLocation': GeoPoint(currentLat, currentLng),
        'destinationLocation': GeoPoint(destLat, destLng),
        'distanceToDestination': distance,
        'checkInTime': FieldValue.serverTimestamp(),
        'status': distance <= 500 ? 'success' : 'pending',
      });
    } catch (e) {
      print('Lỗi lưu check-in: $e');
      rethrow;
    }
  }

  /// Lấy danh sách check-in của user
  Stream<List<CheckIn>> getUserCheckIns(String userId) {
    return _db
        .collection('check_ins')
        .where('userId', isEqualTo: userId)
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CheckIn.fromFirestore(doc)).toList());
  }
}
