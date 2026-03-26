import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tour_model.dart';
import '../models/booking_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String TOUR_CACHE_KEY = 'tours_cache';

  // DANH SÁCH TOUR MẪU (FAKE API) - LUÔN HIỂN THỊ ĐỂ ĐẸP APP
  final List<Tour> _fakeTours = [
    Tour(
      id: 'fake_1',
      title: 'Vịnh Hạ Long - Kỳ Quan Thế Giới',
      description: 'Khám phá vẻ đẹp huyền bí của hàng ngàn đảo đá vôi.',
      price: 2500000,
      totalSlots: 20,
      availableSlots: 15,
      location: 'Quảng Ninh',
      imageUrl: 'https://images.unsplash.com/photo-1559592442-741eafb85a0b?q=80&w=1000',
      highlights: ['Du thuyền 5 sao', 'Thăm hang Sửng Sốt', 'Chèo Kayak'],
      schedule: 'Ngày 1: Hà Nội - Hạ Long. Ngày 2: Thăm hang, về Hà Nội.',
    ),
    Tour(
      id: 'fake_2',
      title: 'Đà Lạt - Thành Phố Ngàn Hoa',
      description: 'Tận hưởng không khí se lạnh và ngắm nhìn đồi thông.',
      price: 1800000,
      totalSlots: 30,
      availableSlots: 10,
      location: 'Lâm Đồng',
      imageUrl: 'https://images.unsplash.com/photo-1589415413190-2e9949666063?q=80&w=1000',
      highlights: ['Vườn hoa thành phố', 'Thác Datanla', 'Chợ đêm'],
      schedule: 'Ngày 1: Tham quan dinh thự cổ. Ngày 2: Check-in cafe view thung lũng.',
    ),
    Tour(
      id: 'fake_3',
      title: 'Sapa - Nơi Gặp Gỡ Đất Trời',
      description: 'Chinh phục đỉnh Fansipan và khám phá bản làng dân tộc.',
      price: 3200000,
      totalSlots: 25,
      availableSlots: 20,
      location: 'Lào Cai',
      imageUrl: 'https://images.unsplash.com/photo-1504457047772-27fb18144da9?q=80&w=1000',
      highlights: ['Đỉnh Fansipan', 'Bản Cát Cát', 'Thung lũng Mường Hoa'],
      schedule: 'Ngày 1: Fansipan. Ngày 2: Trekking bản làng.',
    ),
  ];

  // 1. TOUR FETCHING WITH OFFLINE CACHING & FAKE DATA
  Stream<List<Tour>> get tours {
    return _db.collection('tours').snapshots().asyncMap((snapshot) async {
      // Lấy từ Firebase
      List<Tour> firebaseTours = snapshot.docs.map((doc) => Tour.fromFirestore(doc)).toList();
      
      // Lưu vào Cache
      if (firebaseTours.isNotEmpty) {
        await _saveToursToCache(firebaseTours);
      }
      
      // TRẢ VỀ CẢ HAI (FIREBASE + FAKE) ĐỂ KHÔNG BỊ TRỐNG MÀN HÌNH
      return [...firebaseTours, ..._fakeTours];
    }).handleError((error) async {
      // Nếu mất mạng hoặc lỗi, lấy từ Cache + Fake
      List<Tour> cached = await _loadToursFromCache();
      return [...cached, ..._fakeTours];
    });
  }

  Future<void> _saveToursToCache(List<Tour> tours) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> tourList = tours.map((t) => t.toMap()).toList();
    await prefs.setString(TOUR_CACHE_KEY, json.encode(tourList));
  }

  Future<List<Tour>> _loadToursFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString(TOUR_CACHE_KEY);
    if (cachedData != null) {
      Iterable decoded = json.decode(cachedData);
      return decoded.map((t) => Tour(
        id: 'cache',
        title: t['title'] ?? '',
        description: t['description'] ?? '',
        price: (t['price'] ?? 0).toDouble(),
        totalSlots: t['totalSlots'] ?? 0,
        availableSlots: t['availableSlots'] ?? 0,
        location: t['location'] ?? '',
        imageUrl: t['imageUrl'] ?? '',
      )).toList();
    }
    return [];
  }

  // 2. HÀM ĐẶT VÉ NÂNG CẤP
  Future<String> bookTour(String userId, String tourId, {String? voucherCode}) async {
    if (tourId.startsWith('fake_')) return "Đặt vé tour mẫu thành công!";

    DocumentReference tourRef = _db.collection('tours').doc(tourId);
    DocumentReference bookingRef = _db.collection('bookings').doc();

    return _db.runTransaction((transaction) async {
      DocumentSnapshot tourSnapshot = await transaction.get(tourRef);
      if (!tourSnapshot.exists) throw Exception("Tour không tồn tại!");

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
        throw Exception("Đã hết chỗ!");
      }
    });
  }

  Future<void> addTour(Tour tour) async {
    await _db.collection('tours').add(tour.toMap());
  }
}
