import 'package:flutter/material.dart';
import 'dashboard_layout.dart';
import 'soil_health/soil_health_page.dart';
import 'crop_health/crop_health_page.dart';
import 'green_credits/green_credits_page.dart';
import 'irrigation/irrigation_page.dart';
import 'components/farm_map_widget.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentPage: 'Dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5F2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Welcome back, here's your farm's overview.",
            style: TextStyle(fontSize: 16, color: Color(0xFF5F7D5F)),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Irrigation Needs',
                  icon: Icons.water_drop,
                  value: 'Medium',
                  subtitle: 'Next schedule in 2 days',
                  linkText: 'View Irrigation Guide →',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const IrrigationPage()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricCard(
                  title: 'Crop Health',
                  icon: Icons.local_florist,
                  value: 'Good',
                  subtitle: '85% of fields are healthy',
                  linkText: 'View Health Map →',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CropHealthPage()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricCard(
                  title: 'Soil Moisture',
                  icon: Icons.terrain,
                  value: '55%',
                  subtitle: 'Optimal range: 45-65%',
                  linkText: 'View Soil Details →',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SoilHealthPage()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _GreenCreditsCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GreenCreditsPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(flex: 2, child: _PestAlertsCard()),
            ],
          ),
          const SizedBox(height: 16),
          const _FarmMapCard(),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final String subtitle;
  final String linkText;
  final VoidCallback onTap;

  const _MetricCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.subtitle,
    required this.linkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD4E7D4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5F7D5F),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: const Color(0xFF5F7D5F), size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5F2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF5F7D5F)),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: onTap,
            child: Text(
              linkText,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D8B3E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreenCreditsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _GreenCreditsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD4E7D4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Green Credits',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5F7D5F),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.eco, color: Color(0xFF5F7D5F), size: 20),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '1,250',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5F2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '+20 this month',
            style: TextStyle(fontSize: 13, color: Color(0xFF5F7D5F)),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: onTap,
            child: const Text(
              'View Eco Score →',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF2D8B3E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PestAlertsCard extends StatelessWidget {
  const _PestAlertsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD4E7D4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Pest Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5F2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Potential threats detected in your fields.',
            style: TextStyle(fontSize: 13, color: Color(0xFF5F7D5F)),
          ),
          const SizedBox(height: 20),
          const _PestAlertItem(
            name: 'Aphids',
            field: 'Field 3 - Moderate risk',
            severity: 'High',
            severityColor: Colors.red,
          ),
          const SizedBox(height: 12),
          const _PestAlertItem(
            name: 'Spider Mites',
            field: 'Field 1 - Low risk',
            severity: 'Low',
            severityColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}

class _PestAlertItem extends StatelessWidget {
  final String name;
  final String field;
  final String severity;
  final Color severityColor;

  const _PestAlertItem({
    required this.name,
    required this.field,
    required this.severity,
    required this.severityColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5F2E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                field,
                style: const TextStyle(fontSize: 13, color: Color(0xFF5F7D5F)),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              severity,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: severityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmMapCard extends StatelessWidget {
  const _FarmMapCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on, color: Color(0xFF2D5F2E), size: 24),
              SizedBox(width: 8),
              Text(
                'My Farm',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5F2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'An overview of your registered land.',
            style: TextStyle(fontSize: 14, color: Color(0xFF5F7D5F)),
          ),
          const SizedBox(height: 20),
          const SizedBox(
            height: 300,
            child: FarmMapWidget(),
          ),
        ],
      ),
    );
  }
}
