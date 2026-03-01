import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_layout.dart';
import 'components/field_details_page.dart';
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

        String targetCrop = "Analyzing...";
    if (analysis != null) {
      if (analysis['crop_viability_analysis'] != null && analysis['crop_viability_analysis'].isNotEmpty) {
        targetCrop = analysis['crop_viability_analysis'][0]['crop'] ?? "Unknown";
      } else {
         targetCrop = "Pending Setup";
      }
    }
        String moisture = "Pending Backend";
        String healthStatus = "Pending Backend";
        List<dynamic> fertRecs = [];
        List<dynamic> cropRecs = [];
        String? systemMessage;

        // Make v2Report accessible to the build method
        Map<String, dynamic>? currentV2Report;

        if (analysis != null) {
          // V2 Structure Parsing
          final v2Report = analysis['v2_engine_report'] as Map<String, dynamic>?;
          currentV2Report = v2Report;
          
          if (v2Report != null) {
               final envData = v2Report['environmental_data'] as Map<String, dynamic>?;
               if (envData != null && envData.containsKey('soil')) {
                  final soil = envData['soil'] as Map<String, dynamic>;
                  if (soil.containsKey('soil_moisture')) {
                      moisture = "${soil['soil_moisture']}%";
                  }
               } else if (v2Report.containsKey('system_message') && v2Report['system_message'].toString().contains('Non-arable')) {
                  moisture = "N/A";
               }
    
              // 2. Focused Analysis (Fertilizer, Irrigation Health)
              final focusedAnalysis = v2Report['focused_analysis'] as Map<String, dynamic>?;
              if (focusedAnalysis != null) {
                  fertRecs = focusedAnalysis['fertilizer_recommendations'] ?? [];
                  
                  final irrigation = focusedAnalysis['irrigation'];
                  if (irrigation != null && irrigation is Map) {
                      healthStatus = irrigation['status']?.toString() ?? "Analyzed";
                  } else {
                      healthStatus = "Analyzed";
                  }
              } else if (v2Report.containsKey('system_message') && v2Report['system_message'].toString().contains('Non-arable')) {
                  healthStatus = "Non-Arable Land";
              }
              
              // 3. Top Crops
              final topCrops = v2Report['top_crops'] as List<dynamic>?;
              if (topCrops != null && topCrops.isNotEmpty) {
                  cropRecs = topCrops;
              }
              
              systemMessage = v2Report['system_message'] as String?;
          }
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

          // Recommendations Notice
          if (systemMessage != null && systemMessage!.contains("Non-arable"))
             Text("Engine Alert: $systemMessage", style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic))
          else if (currentV2Report == null)
             const Text("Awaiting Engine V2 Analysis completion...", style: TextStyle(fontSize: 13, color: Colors.black54, fontStyle: FontStyle.italic))
          else ...[
             const Text(
               "Advanced Analysis Available",
               style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D5F2E)),
             ),
             const SizedBox(height: 8),
             const Text(
               "Includes timeline, fertilizer schedules, secondary crop viability, and future seasonal outlook.",
               style: TextStyle(fontSize: 11, color: Colors.black54),
             ),
             const SizedBox(height: 16),
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (context) => FieldDetailsPage(field: field, v2Report: currentV2Report!),
                     ),
                   );
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFF2D5F2E),
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 12),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                   elevation: 0,
                 ),
                 child: const Text("View Detailed Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
               ),
             )
          ]
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

