import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
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
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tạo tài khoản", style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("Tham gia cộng đồng du lịch ngay", style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 10),
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
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 20, offset: Offset(0, 10))],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
                              child: TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(hintText: "Họ và tên", hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
                              child: TextField(
                                controller: _emailController,
                                decoration: const InputDecoration(hintText: "Email", hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(hintText: "Mật khẩu", hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
                      GestureDetector(
                        onTap: () async {
                          if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ thông tin')));
                            return;
                          }
                          setState(() => _isLoading = true);
                          final result = await authService.signUp(_emailController.text, _passwordController.text, _nameController.text);
                          setState(() => _isLoading = false);
                          if (result == null) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thành công!')));
                          } else {
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
                              : const Text("Đăng ký ngay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Đã có tài khoản? Đăng nhập", style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold)),
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
