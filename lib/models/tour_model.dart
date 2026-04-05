import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleItem {
  final String title;
  final String content;

  ScheduleItem({required this.title, required this.content});

  Map<String, dynamic> toMap() {
    return {'title': title, 'content': content};
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
    );
  }
}

class Tour {
  final String id;
  final String title;
  final String description;
  final double price;
  final int totalSlots;
  final int availableSlots;
  final String location;
  final String category;
  final GeoPoint? geoPoint;
  final String imageUrl;
  final List<String> images;
  final List<String> highlights;
  final List<ScheduleItem> scheduleItems;

  Tour({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.totalSlots,
    required this.availableSlots,
    required this.location,
    required this.category,
    this.geoPoint,
    required this.imageUrl,
    this.images = const [],
    this.highlights = const [],
    this.scheduleItems = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'totalSlots': totalSlots,
      'availableSlots': availableSlots,
      'location': location,
      'category': category,
      'geoPoint': geoPoint,
      'imageUrl': imageUrl,
      'images': images,
      'highlights': highlights,
      'scheduleItems': scheduleItems.map((item) => item.toMap()).toList(),
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
      category: data['category'] ?? 'Khác',
      geoPoint: data['geoPoint'],
      imageUrl: data['imageUrl'] ?? '',
      images: data['images'] != null ? List<String>.from(data['images']) : [],
      highlights: data['highlights'] != null ? List<String>.from(data['highlights']) : [],
      scheduleItems: (data['scheduleItems'] as List? ?? [])
          .map((item) => ScheduleItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
