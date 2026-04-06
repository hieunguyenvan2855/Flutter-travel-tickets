import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/revenue_report_model.dart';

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
    // Đã sửa tên hàm cho đúng với DatabaseService
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickStats(fmt),
                  const SizedBox(height: 25),
                  _buildSectionTitle('Xu hướng doanh thu theo tháng'),
                  _buildMonthlyChart(fmt),
                  const SizedBox(height: 25),
                  _buildSectionTitle('Tỷ lệ doanh thu theo danh mục'),
                  _buildCategoryAnalysis(fmt),
                  const SizedBox(height: 25),
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
    return Row(
      children: [
        _statCard('Tổng thu', fmt.format(total), Colors.blue[900]!),
        const SizedBox(width: 10),
        _statCard('Đã bán', '${_report!.totalTickets} vé', Colors.orange[700]!),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FittedBox(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(NumberFormat fmt) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _report!.monthlyRevenue.isEmpty ? 100 : _report!.monthlyRevenue.reduce((a, b) => a > b ? a : b) * 1.2,
          barGroups: List.generate(12, (i) => BarChartGroupData(
            x: i + 1,
            barRods: [BarChartRodData(toY: _report!.monthlyRevenue[i], color: Colors.blue[400], width: 12, borderRadius: BorderRadius.circular(2))],
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
    double total = _report!.monthlyRevenue.isEmpty ? 0 : _report!.monthlyRevenue.reduce((a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: _report!.revenueByCategory.entries.map((e) {
          double percent = total > 0 ? (e.value / total) * 100 : 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(value: percent / 100, backgroundColor: Colors.grey[200], color: Colors.blue[700], minHeight: 6),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopTours(NumberFormat fmt) {
    return Column(
      children: _report!.topTours.map((tour) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)), child: Icon(Icons.stars, color: Colors.orange[700])),
          title: Text(tour['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Đã bán: ${tour['sales']} vé'),
          trailing: Text(fmt.format(tour['revenue']), style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold)),
        ),
      )).toList(),
    );
  }
}
