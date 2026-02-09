import 'package:flutter/material.dart';
import '../dashboard_layout.dart';
import 'components/soil_health_charts.dart';

class SoilHealthPage extends StatelessWidget {
  const SoilHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentPage: 'Soil Health',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 8),
          Text(
            "Soil Health",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            "Live data from your ground-truth IoT sensors.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 24),
          SoilHealthCharts(),
        ],
      ),
    );
  }
}
