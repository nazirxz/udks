// lib/widgets/manager_sales_chart_widget.dart
import 'package:flutter/material.dart';

class ManagerSalesChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> chartData;

  const ManagerSalesChartWidget({Key? key, required this.chartData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistik Penjualan Mingguan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Total barang terjual per hari',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: _buildBarChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    print('=== CHART WIDGET DEBUG ===');
    print('chartData.isEmpty: ${chartData.isEmpty}');
    print('chartData: $chartData');
    
    if (chartData.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Find max value for scaling
    final maxValue = chartData
        .map((data) => (data['total_items'] ?? 0) as int)
        .reduce((max, current) => current > max ? current : max);
    final scaledMaxValue = maxValue > 0 ? maxValue + (maxValue * 0.1) : 100;
    
    print('maxValue: $maxValue');
    print('scaledMaxValue: $scaledMaxValue');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: chartData.map((data) {
          final totalItems = (data['total_items'] ?? 0).toDouble();
          final dayShort = data['day_short'] ?? '';
          final barHeight = scaledMaxValue > 0 ? (totalItems / scaledMaxValue) * 180 : 0;

          print('Day: $dayShort, Items: $totalItems, Height: $barHeight');

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Value label on top of bar (always show, even if 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${totalItems.toInt()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: totalItems > 0 ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                  
                  // Bar (show at least small height even when 0)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    width: double.infinity,
                    height: totalItems > 0 ? barHeight.clamp(5, 180) : 5, // Minimum 5px height
                    constraints: const BoxConstraints(maxWidth: 40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: totalItems > 0
                            ? [
                                Colors.blue.shade300,
                                Colors.blue.shade600,
                              ]
                            : [
                                Colors.grey.shade200,
                                Colors.grey.shade300,
                              ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      boxShadow: totalItems > 0
                          ? [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Day label
                  Text(
                    dayShort,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}