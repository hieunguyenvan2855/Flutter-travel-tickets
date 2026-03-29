import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  bool _isLoading = true;

  // Mảng lưu trữ doanh thu của 12 tháng (từ tháng 1 đến tháng 12)
  List<double> _monthlyRevenue = List.filled(12, 0.0);
  double _totalRevenueYear = 0.0;
  int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _fetchRevenueData(); // Gọi hàm lấy dữ liệu ngay khi mở màn hình
  }

  // =========================================================================
  // LOGIC TASK 3.4: TRUY VẤN FIRESTORE VÀ TÍNH TỔNG DOANH THU THEO THÁNG
  // =========================================================================
  Future<void> _fetchRevenueData() async {
    try {
      // 1. Truy vấn bảng 'bookings', chỉ lấy những đơn hàng đã thanh toán hoặc hoàn thành
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('status', whereIn: ['paid', 'completed']).get();

      List<double> tempRevenue = List.filled(12, 0.0);
      double tempTotalYear = 0.0;

      // 2. Lặp qua từng đơn hàng để cộng dồn tiền vào đúng tháng
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['createdAt'] != null && data['totalPrice'] != null) {
          // Ép kiểu an toàn cho ngày tháng và số tiền
          DateTime date = (data['createdAt'] as Timestamp).toDate();
          double price = (data['totalPrice'] as num).toDouble();

          // Chỉ tính doanh thu của năm hiện tại
          if (date.year == _currentYear) {
            // Index của mảng từ 0-11, tương ứng tháng 1-12
            tempRevenue[date.month - 1] += price;
            tempTotalYear += price;
          }
        }
      }

      // 3. Cập nhật giao diện (UI)
      setState(() {
        _monthlyRevenue = tempRevenue;
        _totalRevenueYear = tempTotalYear;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Lỗi tải doanh thu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Thống kê Doanh thu',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // THẺ TỔNG DOANH THU NĂM
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text('Tổng Doanh Thu Năm $_currentYear',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(
                            currencyFormat.format(_totalRevenueYear),
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text('Biểu đồ doanh thu từng tháng',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // =========================================================================
                  // GIAO DIỆN BIỂU ĐỒ CỘT (BAR CHART)
                  // =========================================================================
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 30, right: 16, left: 16, bottom: 16),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            // Tính cột cao nhất + thêm 20% khoảng trống bên trên
                            maxY: _totalRevenueYear == 0
                                ? 1000000
                                : _monthlyRevenue
                                        .reduce((a, b) => a > b ? a : b) *
                                    1.2,

                            // Cấu hình các thanh tiêu đề (Trục X và Y)
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text('T${value.toInt()}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                      showTitles:
                                          false)), // Ẩn cột số bên trái cho gọn
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(show: false),
                            borderData: FlBorderData(show: false),

                            // Cấu hình hiệu ứng chạm (Touch Tooltip)
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    currencyFormat.format(rod.toY),
                                    const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                            ),

                            // Dữ liệu truyền vào vẽ 12 cột
                            barGroups: List.generate(12, (index) {
                              return BarChartGroupData(
                                x: index + 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: _monthlyRevenue[index],
                                    color: Colors.blue[600],
                                    width: 18, // Độ rộng của cột
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6)),
                                  ),
                                ],
                              );
                            }),
                          ),
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
