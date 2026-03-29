import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'views/auth/login_screen.dart';
import 'views/home/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10)); // Tăng thời gian chờ khởi tạo
  } catch (e) {
    print("Firebase init error: $e");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        // Lắng nghe sự thay đổi của User từ Firebase
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
          catchError: (_, __) => null,
        ),
      ],
      child: MaterialApp(
        title: 'Hệ thống Bán vé Du lịch',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // SỬ DỤNG CONSUMER ĐỂ THEO DÕI SÁT SAO TRẠNG THÁI LOGIN/LOGOUT
    return Consumer<User?>(
      builder: (context, user, child) {
        if (user != null) {
          // Nếu có User -> Vào thẳng Home
          return const HomeScreen();
        } else {
          // Nếu User là null (vừa Đăng xuất xong) -> Chuyển hướng ngay lập tức về Login
          return const LoginScreen();
        }
      },
    );
  }
}
