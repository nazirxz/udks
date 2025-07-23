// lib/widgets/manager_purchase_chart_widget.dart
import 'package:flutter/material.dart';

class ManagerPurchaseChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> chartData;

  const ManagerPurchaseChartWidget({Key? key, required this.chartData}) : super(key: key);

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
              'Statistik Pembelian Mingguan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Total barang masuk per hari',
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: chartData.map((data) {
          final totalItems = (data['total_items'] ?? 0).toDouble();
          final dayShort = data['day_short'] ?? '';
          final barHeight = scaledMaxValue > 0 ? (totalItems / scaledMaxValue) * 180 : 0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Value label on top of bar
                  if (totalItems > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${totalItems.toInt()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 16),
                  
                  // Bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    width: double.infinity,
                    height: barHeight.clamp(0, 180),
                    constraints: const BoxConstraints(maxWidth: 40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: totalItems > 0
                            ? [
                                Colors.green.shade300,
                                Colors.green.shade600,
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
                                color: Colors.green.withOpacity(0.3),
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