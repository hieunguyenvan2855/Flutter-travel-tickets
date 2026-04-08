class RevenueReport {
  final List<double> monthlyRevenue;
  final int totalTickets;
  final Map<String, double> revenueByCategory;
  final List<Map<String, dynamic>> topTours;
  final double averageValue;

  RevenueReport({
    required this.monthlyRevenue,
    required this.totalTickets,
    required this.revenueByCategory,
    required this.topTours,
    required this.averageValue,
  });
}
