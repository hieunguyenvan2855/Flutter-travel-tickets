import 'package:cloud_firestore/cloud_firestore.dart';

class Tour {
  final String id;
  final String title;
  final String description;
  final double price;
  final int totalSlots;
  final int availableSlots;
  final String location;
  final GeoPoint? geoPoint;
  final String imageUrl;
  final List<String> highlights; // Các điểm nổi bật
  final String schedule; // Lịch trình chi tiết

  Tour({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.totalSlots,
    required this.availableSlots,
    required this.location,
    this.geoPoint,
    required this.imageUrl,
    this.highlights = const [],
    this.schedule = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'totalSlots': totalSlots,
      'availableSlots': availableSlots,
      'location': location,
      'geoPoint': geoPoint,
      'imageUrl': imageUrl,
      'highlights': highlights,
      'schedule': schedule,
    };
  }

  factory Tour.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Tour(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      totalSlots: data['totalSlots'] ?? 0,
      availableSlots: data['availableSlots'] ?? 0,
      location: data['location'] ?? '',
      geoPoint: data['geoPoint'],
      imageUrl: data['imageUrl'] ?? '',
      highlights: List<String>.from(data['highlights'] ?? []),
      schedule: data['schedule'] ?? '',
    );
  }
}
