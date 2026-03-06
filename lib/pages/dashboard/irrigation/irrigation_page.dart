import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../dashboard_layout.dart';
import '../../../models/field_model.dart';
import '../../../services/field_service.dart';

class IrrigationPage extends StatefulWidget {
  const IrrigationPage({super.key});

  @override
  State<IrrigationPage> createState() => _IrrigationPageState();
}

class _IrrigationPageState extends State<IrrigationPage> {
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

  Widget _buildResultCard({
    required String title,
    required String advice,
    required String status,
    required double deficit,
    required String crop,
  }) {
    final bool requiresWater = deficit > 0;
    
    return Container(
      width: 380,
      margin: const EdgeInsets.only(bottom: 16, right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: requiresWater ? Colors.orange.shade50 : const Color(0xFFD4E7D4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: requiresWater ? Colors.orange.shade200 : const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: requiresWater ? Colors.orange.shade900 : const Color(0xFF2D5F2E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: requiresWater ? Colors.orange.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  crop,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: requiresWater ? Colors.orange.shade900 : const Color(0xFF2D5F2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(
                requiresWater ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: requiresWater ? Colors.orange.shade700 : const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold,
                  color: requiresWater ? Colors.orange.shade800 : const Color(0xFF2D5F2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (requiresWater)
             Text(
                "Action Required: Apply ${deficit.toStringAsFixed(1)}mm of water per hectare.",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade900,
                ),
             ),
             
          if (requiresWater) const SizedBox(height: 8),

          Text(
            advice,
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentPage: 'Irrigation',
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5F2E)))
        : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Algorithmic Irrigation Guidance",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5F2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Dynamic watering schedules calculated strictly using Penman-Monteith Evapotranspiration (ET0) and 14-day rainfall models.",
            style: TextStyle(fontSize: 16, color: Color(0xFF5F7D5F)),
          ),
          const SizedBox(height: 32),
          
          if (_fields.isEmpty)
              const Text("No active fields to schedule. Please add fields in the Field Management tab.", style: TextStyle(color: Colors.grey))
          else
             Wrap(
               children: _fields.map<Widget>((field) {
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('plots').doc(field.id).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                         return const SizedBox.shrink();
                      }
                      
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data == null || !data.containsKey('analysis')) {
                         return const SizedBox.shrink();
                      }
                      
                      final analysis = data['analysis'] as Map<String, dynamic>;
                      final v2Report = analysis['engine_report'] as Map<String, dynamic>?;
                      
                      if (v2Report == null) {
                         return const SizedBox.shrink();
                      }
                      
                      final focusedAnalysis = v2Report['focused_analysis'] as Map<String, dynamic>?;
                      
                      if (focusedAnalysis == null || !focusedAnalysis.containsKey('irrigation') || focusedAnalysis['irrigation'] == null) {
                         String? sysMsg = v2Report['system_message'] as String?;
                         if (sysMsg != null && sysMsg.contains("Non-arable")) {
                            return _buildResultCard(
                               title: field.name,
                               crop: "None (Invalid Land)",
                               advice: "Engine Override: $sysMsg",
                               status: "Non-Arable Region",
                               deficit: 0.0,
                            );
                         }
                         return const SizedBox.shrink();
                      }
                      
                      // Safety type cast incase it failed formatting
                      dynamic irrigation = focusedAnalysis['irrigation'];
                      if (irrigation is String) {
                         // Fallback if the engine couldn't calculate it
                         return _buildResultCard(
                            title: field.name,
                            crop: focusedAnalysis['crop'] ?? "Unknown",
                            advice: irrigation,
                            status: "Analysis Incomplete",
                            deficit: 0.0,
                         );
                      }
                      
                      final iMap = irrigation as Map<String, dynamic>;
                      
                      return _buildResultCard(
                        title: field.name,
                        crop: focusedAnalysis['crop'] ?? "Unknown",
                        status: iMap['status'] ?? "Analyzed",
                        deficit: (iMap['deficit_mm'] ?? 0.0).toDouble(),
                        advice: iMap['advice'] ?? "No advice provided.",
                      );
                    },
                  );
               }).toList(),
             )
        ],
      ),
    );
  }
}
