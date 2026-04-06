import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'views/auth/login_screen.dart';
import 'views/home/home_screen.dart';
import 'firebase_options.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    HttpClient client = super.createHttpClient(context);
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return client;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  
  try {
    // Kiểm tra nếu Firebase chưa được khởi tạo thì mới khởi tạo
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase init error: $e");
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
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
          catchError: (_, __) => null,
        ),
      ],
      child: MaterialApp(
        title: 'TravelVN',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF0D47A1),
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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
    return Consumer<User?>(
      builder: (context, user, child) {
        return user != null ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
