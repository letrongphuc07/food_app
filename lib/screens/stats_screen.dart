import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
      ),
      body: SingleChildScrollView(
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
                    '156',
                    Icons.shopping_bag,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Doanh thu',
                    '\$1,234',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Sales Chart
            Text(
              'Tổng quan bán hàng',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 3),
                        const FlSpot(1, 1),
                        const FlSpot(2, 4),
                        const FlSpot(3, 2),
                        const FlSpot(4, 5),
                        const FlSpot(5, 3),
                        const FlSpot(6, 4),
                      ],
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
              'Món ăn bán chạy nhất',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _generateBarGroup(0, 80),
                    _generateBarGroup(1, 50),
                    _generateBarGroup(2, 70),
                    _generateBarGroup(3, 30),
                    _generateBarGroup(4, 90),
                  ],
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
              itemCount: 5,
              itemBuilder: (context, index) {
                return _buildOrderItem();
              },
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildOrderItem() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.shopping_bag),
        ),
        title: const Text('Đơn hàng #1234'),
        subtitle: const Text('2 món • \$24.99'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Hoàn thành',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
} 