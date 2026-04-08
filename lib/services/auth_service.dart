import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print("Error getting user data: $e");
    }
    return null;
  }

  Stream<UserModel?> getUserDataStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      return null;
    });
  }

  // --- HÀM ĐỔI MẬT KHẨU AN TOÀN ---
  Future<String?> changePassword(String currentPassword, String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null || user.email == null) return "Chưa đăng nhập";

      // Firebase yêu cầu xác thực lại mật khẩu cũ trước khi cho phép đổi mới
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') return "Mật khẩu hiện tại không đúng";
      if (e.code == 'weak-password') return "Mật khẩu mới quá yếu";
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid, 'name': name, 'email': email, 'role': 'customer', 'bookingHistory': [],
        });
      }
      return null;
    } on FirebaseAuthException catch (e) { return e.message; } catch (e) { return e.toString(); }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) { return e.message; } catch (e) { return e.toString(); }
  }

  Future<void> signOut() async => await _auth.signOut();
}
