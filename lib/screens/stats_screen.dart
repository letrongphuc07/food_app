import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';
import 'package:intl/intl.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final OrderService _orderService = OrderService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê')),
      body: StreamBuilder<List<OrderModel>>(
        stream: _orderService.getAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu đơn hàng: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chưa có dữ liệu đơn hàng.'));
          }

          final allOrders = snapshot.data!;
          double totalRevenue = 0;
          int totalOrders = allOrders.length;

          Map<String, double> dailyRevenueMap = {};
          for (var order in allOrders) {
            final status = order.status.trim();
            if (order.status.trim() == 'Đã hoàn thành' && order.deliveredAt != null && order.totalAmount > 0) {
              final date = DateFormat('yyyy-MM-dd').format(order.deliveredAt!.toLocal());
              dailyRevenueMap[date] = (dailyRevenueMap[date] ?? 0) + order.totalAmount;
              totalRevenue += order.totalAmount;
            }
          }

          final sortedDailyRevenueEntries = dailyRevenueMap.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          final lineChartSpots = sortedDailyRevenueEntries.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
          }).toList();

          Map<String, int> popularItemsMap = {};
          for (var order in allOrders) {
            for (var item in order.items) {
              popularItemsMap[item.name] = (popularItemsMap[item.name] ?? 0) + item.quantity;
            }
          }

          final sortedPopularItemsEntries = popularItemsMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final topPopularItems = sortedPopularItemsEntries.take(5).toList();

          final barChartGroups = topPopularItems.asMap().entries.map((entry) {
            return _generateBarGroup(entry.key, entry.value.value.toDouble());
          }).toList();

          final barChartXTitles = Map.fromEntries(topPopularItems.asMap().entries.map((entry) {
            return MapEntry(entry.key, entry.value.key);
          }));

          final recentOrders = allOrders
              .where((order) => order.status.trim() == 'Đã hoàn thành')
              .toList()
            ..sort((a, b) => b.orderTime.compareTo(a.orderTime));

          final displayRecentOrders = recentOrders.take(5).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard('Tổng đơn hàng', totalOrders.toString(), Icons.shopping_bag, Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard('Doanh thu', '${totalRevenue.toStringAsFixed(0)}₫', Icons.attach_money, Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Tổng quan bán hàng (Doanh thu)', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < sortedDailyRevenueEntries.length) {
                                final date = sortedDailyRevenueEntries[value.toInt()].key;
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(date.substring(5).replaceAll('-', '/'), style: const TextStyle(fontSize: 10)),
                                );
                              }
                              return Container();
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: lineChartSpots,
                          isCurved: true,
                          color: Theme.of(context).primaryColor,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Top 5 Món ăn bán chạy nhất', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: sortedPopularItemsEntries.isNotEmpty ? sortedPopularItemsEntries.first.value.toDouble() * 1.2 : 100,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              final title = barChartXTitles[value.toInt()] ?? '';
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 4.0,
                                child: Text(title, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: barChartGroups,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Đơn hàng gần đây', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayRecentOrders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderItem(displayRecentOrders[index]);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.shopping_bag)),
        title: Text('Đơn hàng #${order.id.substring(0, 6)}...'),
        subtitle: Text('${order.items.length} món • ${order.totalAmount.toStringAsFixed(0)}₫'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusText(order.status),
            style: TextStyle(
              color: _getStatusColor(order.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          // TODO: Navigate to order detail
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.trim()) {
      case 'Đã hoàn thành':
        return Colors.green;
      case 'Đã hủy':
        return Colors.red;
      case 'Đang chuẩn bị':
        return Colors.orange;
      case 'Đang chờ xử lý':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.trim()) {
      case 'Đang chờ xử lý':
        return 'Đang chờ xử lý';
      case 'Đang chuẩn bị':
        return 'Đang chuẩn bị';
      case 'Đã hoàn thành':
        return 'Đã hoàn thành';
      case 'Đã hủy':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  BarChartGroupData _generateBarGroup(int x, double value) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: Colors.orange,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }
}
