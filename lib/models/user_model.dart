class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' or 'customer'
  final List<String> bookingHistory;
  final int points; // Thêm trường điểm tích lũy
  final String rank; // Thêm trường hạng thành viên: 'Bạc', 'Vàng', 'Kim cương'

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.bookingHistory = const [],
    this.points = 0,
    this.rank = 'Bạc',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'bookingHistory': bookingHistory,
      'points': points,
      'rank': rank,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'customer',
      bookingHistory: List<String>.from(map['bookingHistory'] ?? []),
      points: map['points'] ?? 0,
      rank: map['rank'] ?? 'Bạc',
    );
  }
}
