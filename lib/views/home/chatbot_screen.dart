import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  
  // Quản lý kịch bản Menu
  List<Map<String, String>> _currentMenu = [];
  String _menuTitle = "Tôi có thể giúp gì cho bạn?";

  // Dữ liệu kịch bản Đa cấp
  final Map<String, dynamic> _botKnowledge = {
    'main': [
      {'title': '❓ Thanh toán', 'next': 'payment'},
      {'title': '🛡️ Hủy vé', 'next': 'cancel'},
      {'title': '⭐ Điểm & Hạng', 'next': 'loyalty'},
      {'title': '📞 Gặp nhân viên', 'next': 'human'},
    ],
    'payment': [
      {'title': '💳 STK Ngân hàng', 'msg': 'Vietcombank: 0123456789\nChủ TK: CÔNG TY TRAVELVN\nNội dung: [Mã đơn hàng]'},
      {'title': '📱 Ví MoMo', 'msg': 'Số điện thoại MoMo: 0988888888\nTên: NGUYEN VAN A'},
      {'title': '⏳ Thời gian duyệt', 'msg': 'Sau khi bạn nhấn xác nhận thanh toán trên app, Admin sẽ duyệt đơn trong vòng 5-15 phút.'},
      {'title': '⬅️ Quay lại', 'next': 'main'},
    ],
    'cancel': [
      {'title': '📝 Quy trình hủy', 'msg': 'Vào mục "Cá nhân" -> "Lịch sử chuyến đi" -> Vuốt trái vé cần hủy.'},
      {'title': '💰 Chính sách hoàn tiền', 'msg': 'Hủy trước 24h: Hoàn 100%\nHủy sau 24h: Hoàn 50%.'},
      {'title': '⬅️ Quay lại', 'next': 'main'},
    ],
    'loyalty': [
      {'title': '📈 Cách tính điểm', 'msg': 'Mỗi 100.000đ chi tiêu = 10 điểm tích lũy.'},
      {'title': '🏆 Quyền lợi hạng Vàng', 'msg': 'Giảm trực tiếp 5% giá vé và tặng voucher sinh nhật 200k.'},
      {'title': '⬅️ Quay lại', 'next': 'main'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _addBotMessage("Xin chào! 👋 Tôi là trợ lý ảo của TravelVN. Mời bạn chọn vấn đề cần hỗ trợ:");
    _currentMenu = List<Map<String, String>>.from(_botKnowledge['main']);
  }

  void _addBotMessage(String text) {
    setState(() => _messages.add({'isBot': true, 'text': text}));
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() => _messages.add({'isBot': false, 'text': text}));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _handleMenuClick(Map<String, String> item) {
    _addUserMessage(item['title']!);
    
    Future.delayed(const Duration(milliseconds: 400), () {
      if (item.containsKey('msg')) {
        // Nếu có nội dung trả lời trực tiếp
        _addBotMessage(item['msg']!);
      } 
      
      if (item.containsKey('next')) {
        // Nếu là mục để mở menu con
        String nextKey = item['next']!;
        if (nextKey == 'human') {
          _addBotMessage("Đang kết nối bạn với nhân viên hỗ trợ qua Zalo...");
          launchUrl(Uri.parse('https://zalo.me/0123456789'), mode: LaunchMode.externalApplication);
        } else {
          setState(() {
            _currentMenu = List<Map<String, String>>.from(_botKnowledge[nextKey]);
            _menuTitle = "Bạn cần thông tin gì về ${item['title']}?";
          });
          _addBotMessage(_menuTitle);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Trợ lý thông minh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildBubble(msg['text'], msg['isBot']);
              },
            ),
          ),
          _buildNestedMenu(),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isBot) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isBot ? Colors.white : Colors.blue[900],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
        ),
        child: Text(text, style: TextStyle(color: isBot ? Colors.black87 : Colors.white)),
      ),
    );
  }

  Widget _buildNestedMenu() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_menuTitle, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _currentMenu.map((item) => ActionChip(
              label: Text(item['title']!),
              onPressed: () => _handleMenuClick(item),
              backgroundColor: Colors.blue[50],
              labelStyle: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            )).toList(),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
