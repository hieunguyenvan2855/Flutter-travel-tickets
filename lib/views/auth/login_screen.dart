import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [Colors.blue[900]!, Colors.blue[600]!, Colors.blue[400]!],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Chào mừng", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("Khám phá Việt Nam cùng chúng tôi", style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(60), topRight: Radius.circular(60)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 20, offset: Offset(0, 10))],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
                              child: TextField(
                                controller: _emailController,
                                decoration: const InputDecoration(hintText: "Email hoặc Tên đăng nhập", hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(hintText: "Mật khẩu", hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text("Quên mật khẩu?", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: () async {
                          setState(() => _isLoading = true);
                          final result = await authService.signIn(_emailController.text, _passwordController.text);
                          setState(() => _isLoading = false);
                          if (result != null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                          }
                        },
                        child: Container(
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 50),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Colors.blue[900]),
                          child: Center(
                            child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Đăng nhập", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                        child: Text("Chưa có tài khoản? Đăng ký ngay", style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
