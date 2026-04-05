import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class LoyaltyScreen extends StatelessWidget {
  final UserModel userData;
  const LoyaltyScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hạng thành viên & Ưu đãi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Phần Tổng điểm rực rỡ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const Text('TỔNG ĐIỂM TÍCH LŨY', style: TextStyle(color: Colors.white70, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  Text('${userData.points}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                    child: Text('Hạng ${userData.rank}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),

            // 2. Chi tiết các mốc hạng
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CÁC MỐC HẠNG & ƯU ĐÃI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildRankInfo(
                    'Hạng Bạc', 
                    '0 - 199 điểm', 
                    'Nhận tin tức tour mới nhất, hỗ trợ 24/7.',
                    Colors.grey,
                    userData.rank == 'Bạc'
                  ),
                  _buildRankInfo(
                    'Hạng Vàng', 
                    '200 - 499 điểm', 
                    'Giảm giá 5% tất cả các tour, ưu tiên chọn chỗ ngồi tốt.',
                    Colors.amber[700]!,
                    userData.rank == 'Vàng'
                  ),
                  _buildRankInfo(
                    'Hạng Kim cương', 
                    'Trên 500 điểm', 
                    'Giảm giá 10% tất cả các tour, tặng quà sinh nhật, miễn phí hủy vé.',
                    Colors.blue,
                    userData.rank == 'Kim cương'
                  ),
                ],
              ),
            ),

            // 3. Quy tắc tính điểm
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quy tắc tích điểm', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('• Mỗi chuyến đi hoàn tất: +100 điểm'),
                  Text('• Đánh giá tour sau chuyến đi: +20 điểm'),
                  Text('• Điểm dùng để nâng hạng và nhận ưu đãi trực tiếp khi đặt vé.'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRankInfo(String name, String condition, String perk, Color color, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: isCurrent ? Border.all(color: color, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium, color: color, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                    if (isCurrent) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    ]
                  ],
                ),
                Text(condition, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 5),
                Text(perk, style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
