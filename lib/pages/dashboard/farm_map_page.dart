import 'package:flutter/material.dart';
import 'dashboard_layout.dart';
import 'components/farm_map_widget.dart';

class FarmMapPage extends StatelessWidget {
  const FarmMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentPage: 'Map',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Farm Map',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5F2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "An overview of your registered land.",
            style: TextStyle(fontSize: 16, color: Color(0xFF5F7D5F)),
          ),
          const SizedBox(height: 32),
          Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: const FarmMapWidget(),
          ),
        ],
      ),
    );
  }
}
