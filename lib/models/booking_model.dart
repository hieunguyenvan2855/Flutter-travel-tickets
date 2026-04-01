import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String bookingId;
  final String userId;
  final String tourId;
  final String tourName; // Thêm tên tour để hiển thị nhanh trong lịch sử
  final int tickets;     // Số lượng vé
  final String status;    // 'pending', 'paid', 'confirmed', 'cancelled'
  final DateTime timestamp;
  final double totalPrice;
  final bool isReviewed;  // Trạng thái đã đánh giá hay chưa

  Booking({
    required this.bookingId,
    required this.userId,
    required this.tourId,
    required this.tourName,
    required this.tickets,
    required this.status,
    required this.timestamp,
    required this.totalPrice,
    this.isReviewed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tourId': tourId,
      'tourName': tourName,
      'tickets': tickets,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'totalPrice': totalPrice,
      'isReviewed': isReviewed,
    };
  }

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Booking(
      bookingId: doc.id,
      userId: data['userId'] ?? '',
      tourId: data['tourId'] ?? '',
      tourName: data['tourName'] ?? 'Tour Du Lịch',
      tickets: data['tickets'] ?? 1,
      status: data['status'] ?? 'pending',
      // Sử dụng createdAt thay vì timestamp để đồng bộ với hàm bookTour
      timestamp: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      isReviewed: data['isReviewed'] ?? false,
    );
  }
}
