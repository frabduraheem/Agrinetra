import 'package:flutter/material.dart';
import '../../../../models/field_model.dart';
import 'package:intl/intl.dart';

class FieldDetailsPage extends StatelessWidget {
  final Field field;
  final Map<String, dynamic> v2Report;

  const FieldDetailsPage({
    super.key,
    required this.field,
    required this.v2Report,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Check if planted
    final Map<String, dynamic>? activeCrop = v2Report['active_crop_status'] as Map<String, dynamic>?;
    final bool isPlanted = activeCrop != null;

    // 2. Parse Primary/Viable Crops
    final List<dynamic> viabilityAnalysis = v2Report['crop_viability_analysis'] ?? [];
    
    // 3. Parse interim strategy
    final Map<String, dynamic>? interimStrategy = v2Report['interim_crop_strategy'] as Map<String, dynamic>?;

    // 4. Parse Upcoming Seasons
    final List<dynamic> upcomingSeasons = v2Report['upcoming_seasons'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        title: Text('${field.name} Analysis', style: const TextStyle(color: Color(0xFF2D5F2E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF2D5F2E)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE8F5E9), height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER METRICS ---
            if (isPlanted) ...[
              Row(
                children: [
                  Expanded(child: _buildHeaderMetric(Icons.eco, "Currently Planted", activeCrop['crop']?.toString() ?? "Unknown", color: Colors.green.shade700)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHeaderMetric(
                      Icons.agriculture, 
                      "Est. Harvest", 
                      activeCrop['occupied_until']?.toString() ?? "N/A",
                      color: Colors.orange.shade700
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Active Crop Details
              const Text("Active Crop Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D5F2E))),
              const SizedBox(height: 12),
              
              if (activeCrop['irrigation_schedule'] != null) ...[
                 _buildIrrigationCard(activeCrop['irrigation_schedule'] as Map<String, dynamic>),
                 const SizedBox(height: 12),
              ],
              
              _buildListCard(activeCrop['fertilizer_recommendations'] as List<dynamic>? ?? [], "No specific fertilizer required."),
              const SizedBox(height: 24),
              
              const Divider(color: Color(0xFFC8E6C9), thickness: 2),
              const SizedBox(height: 24),
              
              const Text("Post-Harvest Viable Crops", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D5F2E))),
              const SizedBox(height: 12),
              if (viabilityAnalysis.isNotEmpty)
                _buildAlternativeCropsList(viabilityAnalysis)
              else
                const Text("No viable crops identified.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                
            ] else ...[
              Row(
                children: [
                  Expanded(child: _buildHeaderMetric(Icons.landscape, "Field Status", "Barren", color: Colors.brown.shade600)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHeaderMetric(
                      Icons.format_list_numbered, 
                      "Viable Options", 
                      "${viabilityAnalysis.length} Crops",
                      color: const Color(0xFF2D5F2E)
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // --- INTERCROPPING & INTERIM ---
              if (interimStrategy != null) ...[
                  const Text("Growth & Yield Optimization", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D5F2E))),
                  const SizedBox(height: 12),
                  _buildInterimCard(interimStrategy),
                  const SizedBox(height: 24),
              ],

              // --- ALTERNATIVE VIABLE CROPS ---
              const Text("Top Viable Crops", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D5F2E))),
              const SizedBox(height: 12),
              if (viabilityAnalysis.isNotEmpty)
                 _buildAlternativeCropsList(viabilityAnalysis)
              else
                 const Text("No viable crops identified.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            ],

            const SizedBox(height: 24),

            // --- UPCOMING SEASONS ---
            /*
            if (upcomingSeasons.isNotEmpty) ...[
               const Text("Future Seasonal Outlook", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D5F2E))),
               const SizedBox(height: 12),
               _buildSeasonsList(upcomingSeasons),
               const SizedBox(height: 24),
            ]
            */
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderMetric(IconData icon, String label, String value, {Color color = const Color(0xFF2D5F2E)}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8E6C9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color.withOpacity(0.8)),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontWeight: FontWeight.w500))),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildIrrigationCard(Map<String, dynamic> schedule) {
    final status = schedule['status']?.toString() ?? 'Unknown';
    final advice = schedule['advice']?.toString() ?? '';
    final isRequired = status.contains('Required');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRequired ? Colors.blue.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isRequired ? Colors.blue.shade200 : Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             children: [
               Icon(Icons.water_drop, size: 20, color: isRequired ? Colors.blue.shade700 : Colors.green.shade700),
               const SizedBox(width: 8),
               Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: isRequired ? Colors.blue.shade700 : Colors.green.shade700, fontSize: 16)),
             ],
           ),
           const SizedBox(height: 12),
           Text(advice, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildListCard(List<dynamic> items, String emptyFallback) {
    if (items.isEmpty) {
      return Text(emptyFallback, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(fontSize: 16, color: Color(0xFF5F7D5F), height: 1.2)),
                Expanded(child: Text(e.toString(), style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInterimCard(Map<String, dynamic> strategy) {
     return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Light amber for strategy
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFECB3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             children: [
               const Icon(Icons.lightbulb_outline, size: 20, color: Color(0xFFF57F17)),
               const SizedBox(width: 8),
               Text("Interim Strategy: ${strategy['interim_crop'] ?? 'Unknown'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF57F17), fontSize: 16)),
             ],
           ),
           const SizedBox(height: 12),
           Text(strategy['reasoning'] ?? '', style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
        ],
      ),
     );
  }

  Widget _buildAlternativeCropsList(List<dynamic> crops) {
     if (crops.isEmpty) return const Text("No viable crops identified.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
     
     // Limit to top 5 alternatives to prevent massive scrolling lists
     final displayCrops = crops.take(5).toList();
     
     return Column(
        children: displayCrops.map((c) {
           final Map<String, dynamic> cmap = c as Map<String, dynamic>;
           final score = (cmap['score'] as num?)?.toDouble() ?? 0.0;
           final timeline = cmap['growth_timeline'] as Map<String, dynamic>?;
           final fertilizers = cmap['fertilizer_recommendations'] as List<dynamic>? ?? [];
           final intercrops = cmap['intercropping_partners'] as List<dynamic>? ?? [];
           
           return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8F5E9)),
                 boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Theme(
                data: ThemeData().copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                     cmap['crop']?.toString() ?? 'Unknown', 
                     style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D5F2E), fontSize: 16)
                  ),
                  subtitle: Text(
                     "Viability Score: ${score.toInt()}", 
                     style: TextStyle(fontSize: 13, color: score > 75 ? Colors.green : Colors.orange.shade700)
                  ),
                  childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  children: [
                     const Divider(color: Color(0xFFE8F5E9)),
                     const SizedBox(height: 8),
                     if (timeline != null) ...[
                        const Text("Timeline", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text("Est. Planting: ${timeline['estimated_planting'] ?? 'N/A'}", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                        Text("Maturity: ${timeline['days_to_maturity'] ?? 'N/A'} Days", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                        const SizedBox(height: 12),
                     ],
                     if (fertilizers.isNotEmpty) ...[
                        const Text("Required Fertilizer", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        ...fertilizers.map((f) => Text("• $f", style: const TextStyle(fontSize: 13, color: Colors.black87))).toList(),
                        const SizedBox(height: 12),
                     ],
                     if (intercrops.isNotEmpty) ...[
                        const Text("Viable Intercrops", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(intercrops.join(', '), style: const TextStyle(fontSize: 13, color: Colors.black54, fontStyle: FontStyle.italic)),
                     ]
                  ],
                ),
              ),
           );
        }).toList(),
     );
  }

  Widget _buildSeasonsList(List<dynamic> seasons) {
     return Column(
        children: seasons.map((s) {
           final Map<String, dynamic> smap = s as Map<String, dynamic>;
           final temp = smap['projected_avg_temp_c'] != null ? "${(smap['projected_avg_temp_c'] as num).toStringAsFixed(1)}°C" : "Unk";
           final List<dynamic> ts = smap['top_crops'] ?? [];
           final topCrop1 = ts.isNotEmpty ? (ts.first as Map)['crop'] : "None";
           
           return Container(
             margin: const EdgeInsets.only(bottom: 12),
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8F5E9)),
             ),
             child: Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(10),
                     decoration: const BoxDecoration(
                       shape: BoxShape.circle,
                       color: Color(0xFFE8F5E9),
                     ),
                     child: const Icon(Icons.cloud_outlined, color: Color(0xFF2D5F2E), size: 20),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(smap['timeframe']?.toString() ?? 'Future', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                           const SizedBox(height: 4),
                           Text("Est. Temp: $temp | Best Crop: $topCrop1", style: const TextStyle(fontSize: 12, color: Color(0xFF5F7D5F))),
                        ],
                     ),
                   )
                ],
             ),
           );
        }).toList(),
     );
  }
}
