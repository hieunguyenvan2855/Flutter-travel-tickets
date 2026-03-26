class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' or 'customer'
  final List<String> bookingHistory;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.bookingHistory = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'bookingHistory': bookingHistory,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'customer',
      bookingHistory: List<String>.from(map['bookingHistory'] ?? []),
    );
  }
}
