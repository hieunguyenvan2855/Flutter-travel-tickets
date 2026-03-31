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

/// Check-in model để lưu lịch sử check-in của khách
class CheckIn {
  final String checkInId;
  final String userId;
  final String tourId;
  final String bookingId;
  final GeoPoint checkInLocation; // Vị trí check-in hiện tại
  final GeoPoint destinationLocation; // Vị trí điểm đến tour
  final double distanceToDestination; // Khoảng cách (mét)
  final DateTime checkInTime;
  final String status; // 'success' hoặc 'pending'
  final String? notes;

  CheckIn({
    required this.checkInId,
    required this.userId,
    required this.tourId,
    required this.bookingId,
    required this.checkInLocation,
    required this.destinationLocation,
    required this.distanceToDestination,
    required this.checkInTime,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tourId': tourId,
      'bookingId': bookingId,
      'checkInLocation': checkInLocation,
      'destinationLocation': destinationLocation,
      'distanceToDestination': distanceToDestination,
      'checkInTime': checkInTime,
      'status': status,
      'notes': notes,
    };
  }

  factory CheckIn.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CheckIn(
      checkInId: doc.id,
      userId: data['userId'] ?? '',
      tourId: data['tourId'] ?? '',
      bookingId: data['bookingId'] ?? '',
      checkInLocation: data['checkInLocation'] ?? const GeoPoint(0, 0),
      destinationLocation: data['destinationLocation'] ?? const GeoPoint(0, 0),
      distanceToDestination: (data['distanceToDestination'] ?? 0).toDouble(),
      checkInTime: (data['checkInTime'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      notes: data['notes'],
    );
  }
}
