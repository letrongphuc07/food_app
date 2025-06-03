import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/order_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import 'package:intl/intl.dart'; // For date formatting

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
      appBar: AppBar(
        title: const Text('Thống kê'),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _orderService.getAllOrders(), // Stream all orders
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

          // --- Data Processing for Charts and Summary ---

          // Calculate Total Orders and Total Revenue
          double totalRevenue = 0;
          int totalOrders = allOrders.length;

          // Aggregate Daily Revenue for LineChart
          Map<String, double> dailyRevenueMap = {};
          for (var order in allOrders) {
            if (order.status == 'Completed' && order.deliveredAt != null) {
              final date = DateFormat('yyyy-MM-dd').format(order.deliveredAt!.toLocal());
              dailyRevenueMap[date] = (dailyRevenueMap[date] ?? 0) + order.totalAmount;
              totalRevenue += order.totalAmount; // Also calculate total revenue here
            }
          }

          final sortedDailyRevenueEntries = dailyRevenueMap.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          final lineChartSpots = sortedDailyRevenueEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final date = entry.value.key;
            final revenue = entry.value.value;
            // For simplicity, using index as x-value. You might want to use date-based values for better representation.
            return FlSpot(index.toDouble(), revenue);
          }).toList();

          // Aggregate Popular Items for BarChart
          Map<String, int> popularItemsMap = {};
          for (var order in allOrders) {
            for (var item in order.items) { // order.items is a List of OrderItem objects
              final itemName = item.name; // Access using dot operator
              popularItemsMap[itemName] = (popularItemsMap[itemName] ?? 0) + item.quantity; // Access using dot operator
            }
          }

          // Sort popular items and take top N (e.g., top 5)
          final sortedPopularItemsEntries = popularItemsMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final topPopularItems = sortedPopularItemsEntries.take(5).toList(); // Display top 5

          final barChartGroups = topPopularItems.asMap().entries.map((entry) {
            final index = entry.key;
            final itemEntry = entry.value;
            return _generateBarGroup(index, itemEntry.value.toDouble());
          }).toList();

          // Prepare X-axis titles for BarChart
          final barChartXTitles = Map.fromEntries(topPopularItems.asMap().entries.map((entry) {
             final index = entry.key;
             final itemEntry = entry.value;
             return MapEntry(index, itemEntry.key); // Map index to item name
          }));

          // Filter Recent Orders (take the last 5 completed or most recent)
          final recentOrders = allOrders.where((order) => order.status == 'Completed').toList();
          recentOrders.sort((a, b) => b.orderTime.compareTo(a.orderTime)); // Sort by time descending
          final displayRecentOrders = recentOrders.take(5).toList(); // Take top 5

          // --- Build UI with Processed Data ---

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Tổng đơn hàng',
                        totalOrders.toString(), // Use calculated totalOrders
                        Icons.shopping_bag,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Doanh thu',
                        totalRevenue.toStringAsFixed(0) + '₫', // Use calculated totalRevenue in VND
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Sales Chart
                Text(
                  'Tổng quan bán hàng (Doanh thu)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 16),

                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              // Display date or index as x-axis title
                              // For simplicity, just displaying index for now
                               if (value.toInt() < sortedDailyRevenueEntries.length) {
                                 final date = sortedDailyRevenueEntries[value.toInt()].key;
                                 // Format date to a shorter string if needed
                                 return SideTitleWidget(
                                   axisSide: meta.axisSide,
                                   child: Text(date.substring(5).replaceAll('-','/'), style: const TextStyle(fontSize: 10)), // e.g., 06/03
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
                          spots: lineChartSpots, // Use real data spots
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

                // Popular Items
                Text(
                  'Top 5 Món ăn bán chạy nhất',
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 16),

                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: sortedPopularItemsEntries.isNotEmpty ? sortedPopularItemsEntries.first.value.toDouble() * 1.2 : 100, // Adjust maxY based on highest value
                      barTouchData: BarTouchData(enabled: false),
                       titlesData: FlTitlesData(
                         show: true,
                         bottomTitles: AxisTitles(
                           sideTitles: SideTitles(
                             showTitles: true,
                             reservedSize: 40,
                             getTitlesWidget: (value, meta) {
                               // Display item name as x-axis title
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
                      barGroups: barChartGroups, // Use real data groups
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Recent Orders
                Text(
                  'Đơn hàng gần đây',
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 16),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayRecentOrders.length, // Use count of displayRecentOrders (max 5)
                  itemBuilder: (context, index) {
                    final order = displayRecentOrders[index]; // Use displayRecentOrders
                    return _buildOrderItem(order);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper function to build summary card
  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build recent order item based on OrderModel
  Widget _buildOrderItem(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.shopping_bag), // Replace with food image if available in OrderModel
        ),
        title: Text('Đơn hàng #${order.id.substring(0, 6)}...'),
        subtitle: Text('${order.items.length} món • ${order.totalAmount.toStringAsFixed(0)}₫'), // Display item count and total amount in VND
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withOpacity(0.1), // Dynamic color based on status
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusText(order.status), // Display translated status text
            style: TextStyle(
              color: _getStatusColor(order.status), // Dynamic text color
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          // TODO: Navigate to Order Detail Screen (optional)
        },
      ),
    );
  }

  // Helper function to get color based on status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'Processing':
        return Colors.orange;
      case 'Pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Helper function to get translated status text
  String _getStatusText(String status) {
    switch (status) {
      case 'Pending':
        return 'Đang chờ xử lý';
      case 'Processing':
        return 'Đang chuẩn bị';
      case 'Completed':
        return 'Đã hoàn thành';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status; // Return original status if not matched
    }
  }

  // Helper function to generate bar group for BarChart
  BarChartGroupData _generateBarGroup(int x, double value) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: Colors.orange,
          width: 20,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(6),
          ),
        ),
      ],
    );
  }
} 