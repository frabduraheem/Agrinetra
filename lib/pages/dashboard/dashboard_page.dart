import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_layout.dart';
import '../../models/field_model.dart';
import '../../services/field_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _isLoading = true;
  List<Field> _fields = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await FieldService().loadFields();
    final loadedFields = FieldService().getFields();
    
    if (mounted) {
      setState(() {
        _fields = loadedFields;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return DashboardLayout(
      currentPage: 'Dashboard',
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5F2E)))
        : SingleChildScrollView(
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
                
                const SizedBox(height: 16),
                const Text(
                  'Field Insights & Recommendations',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5F2E),
                  ),
                ),
                const SizedBox(height: 16),
                
                if (_fields.isEmpty)
                  const Text("No fields found. Add fields in the Field Management tab.")
                else
                  Wrap(
                    spacing: 16.0,
                    runSpacing: 16.0,
                    children: _fields.map((field) {
                      return SizedBox(
                        width: 360, // Fixed width for each card so they tile nicely
                        height: 360, // Fixed height to prevent varied card heights when chip lines wrap
                        child: _FieldInsightCard(field: field),
                      );
                    }).toList(),
                  ),
              ],
            ),
        ),
    );
  }
}

class _FieldInsightCard extends StatelessWidget {
  final Field field;

  const _FieldInsightCard({required this.field});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('plots').doc(field.id).snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic>? analysis;
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('analysis')) {
            analysis = data['analysis'] as Map<String, dynamic>?;
          }
        }

        String currentCrop = "None";
        if (field.crops != null && field.crops!.isNotEmpty) {
          currentCrop = field.crops!.map((c) => c.name).join(', ');
        }

        String moisture = "Pending Backend";
        String healthStatus = "Pending Backend";
        List<dynamic> fertRecs = [];
        List<dynamic> cropRecs = [];

        if (analysis != null) {
          if (analysis['soil_moisture'] != null) {
            moisture = "${analysis['soil_moisture']}%";
          }
          
          if (analysis['crop_analysis'] != null && (analysis['crop_analysis'] as List).isNotEmpty) {
             // For the dashboard overview, we just grab the first crop's analysis natively
             final firstCrop = (analysis['crop_analysis'] as List).first;
             healthStatus = firstCrop['healthStatus'] ?? "N/A";
             fertRecs = firstCrop['fertilizerRecommendations'] ?? [];
          }

          cropRecs = analysis['suggested_crops'] ?? [];
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAF7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD4E7D4)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                field.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5F2E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4E7D4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "Crop: $currentCrop",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D5F2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniMetric(Icons.water_drop, "Moisture", moisture),
              _buildMiniMetric(Icons.health_and_safety, "Health", healthStatus),
            ],
          ),
          
          const Divider(height: 20, color: Color(0xFFD4E7D4)),

          // Recommendations
          const Text(
            "Fertilizer Recommendations",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D5F2E)),
          ),
          const SizedBox(height: 4),
          if (fertRecs.isEmpty) 
             const Text("- No specific fertilizer recommendations", style: TextStyle(fontSize: 12, color: Colors.black54))
          else
             ...fertRecs.map((e) => Text("- $e", style: const TextStyle(fontSize: 12, color: Colors.black87))).toList(),
             
          const SizedBox(height: 12),
          
          const Text(
            "Suggested Alternative Crops",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D5F2E)),
          ),
          const SizedBox(height: 4),
          if (cropRecs.isEmpty) 
             const Text("- No specific alternatives suggested", style: TextStyle(fontSize: 12, color: Colors.black54))
          else
             Wrap(
               spacing: 6,
               runSpacing: 6,
               children: cropRecs.map((e) {
                 final String cropName = e is Map ? (e['crop'] ?? e.toString()) : e.toString();
                 return Chip(
                   label: Text(cropName, style: const TextStyle(fontSize: 11)),
                   padding: EdgeInsets.zero,
                   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                   backgroundColor: const Color(0xFFE8F5E9),
                   side: const BorderSide(color: Color(0xFFC8E6C9)),
                 );
               }).toList(),
             )
              ]
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniMetric(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5F7D5F)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF5F7D5F))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D5F2E))),
      ],
    );
  }
}

