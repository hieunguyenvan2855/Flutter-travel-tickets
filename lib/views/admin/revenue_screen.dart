import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';

class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  bool _isLoading = true;
  RevenueReport? _report;
  final int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadDetailedReport();
  }

  Future<void> _loadDetailedReport() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final report = await dbService.getDetailedRevenueReport(_currentYear);
    setState(() {
      _report = report;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Báo cáo Doanh thu Chi tiết', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Chỉ số tổng hợp (KPI Cards)
                  _buildQuickStats(fmt),
                  const SizedBox(height: 25),

                  // 2. Biểu đồ xu hướng
                  _buildSectionTitle('Xu hướng doanh thu theo tháng'),
                  _buildMonthlyChart(fmt),
                  const SizedBox(height: 25),

                  // 3. Phân tích theo danh mục
                  _buildSectionTitle('Tỷ lệ doanh thu theo danh mục'),
                  _buildCategoryAnalysis(fmt),
                  const SizedBox(height: 25),

                  // 4. Danh sách Top Tour
                  _buildSectionTitle('Top Tour bán chạy nhất'),
                  _buildTopTours(fmt),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildQuickStats(NumberFormat fmt) {
    double total = _report!.monthlyRevenue.reduce((a, b) => a + b);
    return Column(
      children: [
        Row(
          children: [
            _statCard('TỔNG DOANH THU', fmt.format(total), Colors.blue[900]!, Icons.payments),
            const SizedBox(width: 10),
            _statCard('VÉ ĐÃ BÁN', '${_report!.totalTickets}', Colors.orange[700]!, Icons.confirmation_number),
          ],
        ),
        const SizedBox(height: 10),
        _statCard('GIÁ TRỊ TRUNG BÌNH / VÉ', fmt.format(_report!.averageValue), Colors.teal[700]!, Icons.trending_up, isFullWidth: true),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon, {bool isFullWidth = false}) {
    Widget content = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border(left: BorderSide(color: color, width: 5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                FittedBox(child: Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ],
      ),
    );

    return isFullWidth ? content : Expanded(child: content);
  }

  Widget _buildMonthlyChart(NumberFormat fmt) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _report!.monthlyRevenue.reduce((a, b) => a > b ? a : b) * 1.2,
          barGroups: List.generate(12, (i) => BarChartGroupData(
            x: i + 1,
            barRods: [BarChartRodData(toY: _report!.monthlyRevenue[i], color: Colors.blue[400], width: 10, borderRadius: BorderRadius.circular(2))],
          )),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text('T${v.toInt()}', style: const TextStyle(fontSize: 9)))),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildCategoryAnalysis(NumberFormat fmt) {
    double total = _report!.monthlyRevenue.reduce((a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: _report!.revenueByCategory.entries.map((e) {
          double percent = total > 0 ? (e.value / total) * 100 : 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: percent / 100, backgroundColor: Colors.grey[100], color: Colors.blue[700], minHeight: 8),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopTours(NumberFormat fmt) {
    return Column(
      children: _report!.topTours.map((tour) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.star, color: Colors.blue[900], size: 20),
          ),
          title: Text(tour['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('Đã bán: ${tour['sales']} vé'),
          trailing: Text(fmt.format(tour['revenue']), style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.bold)),
        ),
      )).toList(),
    );
  }
}
