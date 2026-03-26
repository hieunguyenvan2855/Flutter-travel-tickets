import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String bookingId;
  final String userId;
  final String tourId;
  final String status; // 'pending', 'confirmed', 'paid', 'cancelled'
  final DateTime timestamp;
  final double totalPrice;
  final String? voucherCode;

  Booking({
    required this.bookingId,
    required this.userId,
    required this.tourId,
    required this.status,
    required this.timestamp,
    required this.totalPrice,
    this.voucherCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tourId': tourId,
      'status': status,
      'timestamp': timestamp,
      'totalPrice': totalPrice,
      'voucherCode': voucherCode,
    };
  }

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Booking(
      bookingId: doc.id,
      userId: data['userId'] ?? '',
      tourId: data['tourId'] ?? '',
      status: data['status'] ?? 'pending',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      voucherCode: data['voucherCode'],
    );
  }
}
