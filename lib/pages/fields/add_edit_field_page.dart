import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../models/field_model.dart';
import '../../services/field_service.dart';
import '../../widgets/map.dart';

class AddEditFieldPage extends StatefulWidget {
  final Field? field;
  final VoidCallback onFinished; // Callback when save/cancel is done

  const AddEditFieldPage({super.key, this.field, required this.onFinished});

  @override
  State<AddEditFieldPage> createState() => _AddEditFieldPageState();
}

class _AddEditFieldPageState extends State<AddEditFieldPage> {
  final _formKey = GlobalKey<FormState>();
  final FieldService _fieldService = FieldService();
  
  late String _name;
  List<LatLng> _boundary = [];
  List<Crop> _crops = [];
  bool _isCultivated = false;

  bool _isEditing = false;
  String? _fieldId;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.field != null;
    if (_isEditing) {
      _fieldId = widget.field!.id;
      _name = widget.field!.name;
      _boundary = List.from(widget.field!.boundary);
      _crops = List.from(widget.field!.crops);
      _isCultivated = widget.field!.isCultivated;
    } else {
      _name = '';
      _isCultivated = false;
      // _crops.add(Crop(name: '', sowingDate: '', harvestDate: '')); // Don't add default crop initially
    }
  }

  void _openMap() async {
    // Get existing fields, excluding current one if editing
    final existingFields = _fieldService.getFields()
        .where((f) => _isEditing ? f.id != _fieldId : true)
        .map((f) => f.boundary)
        .toList();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapDrawingScreen(
          title: _isEditing ? "Edit Field Boundary" : "Draw Field Boundary",
          initialPoints: _boundary,
          existingPolygons: existingFields,
        ),
      ),
    );

    if (result != null && result is List<LatLng>) {
      setState(() {
        _boundary = result;
      });
    }
  }

  void _saveField() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_boundary.isEmpty || _boundary.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw a valid field boundary on the map.')),
      );
      return;
    }

    final newField = Field(
      id: _fieldId ?? const Uuid().v4(),
      name: _name,
      boundary: _boundary,
      crops: _isCultivated ? _crops : [], // Ensure crops are empty if not cultivated
      isCultivated: _isCultivated,
    );

    String? error;
    if (_isEditing) {
      error = await _fieldService.updateField(newField);
    } else {
      error = await _fieldService.addField(newField);
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      widget.onFinished(); // Call parent callback instead of popping
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(_isEditing ? 'Field updated' : 'Field added')),
      );
    }
  }

  void _addCrop() {
    setState(() {
      _crops.add(Crop(name: '', sowingDate: DateTime.now().toIso8601String(), harvestDate: DateTime.now().add(const Duration(days: 90)).toIso8601String()));
    });
  }

  void _removeCrop(int index) {
    setState(() {
      _crops.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header Row
        Row(
          children: [
            IconButton(
              onPressed: widget.onFinished,
              icon: const Icon(Icons.arrow_back, color: Color(0xFF2D5F2E)),
            ),
            const SizedBox(width: 8),
            Text(
              _isEditing ? 'Edit Field' : 'Add New Field',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF2D5F2E),
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Form Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(
                      labelText: 'Field Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a field name';
                      }
                      return null;
                    },
                    onSaved: (value) => _name = value!,
                  ),
                  const SizedBox(height: 20),
                  const Text('Boundary:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_boundary.isNotEmpty)
                    Text('${_boundary.length} points defined',
                        style: const TextStyle(color: Colors.green)),
                  ElevatedButton.icon(
                    onPressed: _openMap,
                    icon: const Icon(Icons.map),
                    label: Text(_boundary.isEmpty
                        ? 'Draw Boundary on Map'
                        : 'Edit Boundary'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Cultivation Toggle
                  SwitchListTile(
                    title: const Text('Currently Cultivated?', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Enable if you are currently growing crops on this field'),
                    value: _isCultivated,
                    onChanged: (bool value) {
                      setState(() {
                         _isCultivated = value;
                         if (!_isCultivated) {
                           _crops.clear(); // Clear crops if not cultivated
                         }
                      });
                    },
                    secondary: const Icon(Icons.grass),
                  ),

                  if (_isCultivated) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         const Text('Crops:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                         TextButton.icon(
                           onPressed: _addCrop,
                           icon: const Icon(Icons.add),
                           label: const Text('Add Crop'),
                         ),
                      ],
                    ),
                    if (_crops.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("No crops added."),
                      ),
                    ..._crops.asMap().entries.map((entry) {
                      int index = entry.key;
                      Crop crop = entry.value;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("Crop #${index+1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeCrop(index),
                                  ),
                                ],
                              ),
                              TextFormField(
                                initialValue: crop.name,
                                decoration: const InputDecoration(labelText: "Crop Name"),
                                onChanged: (val) => crop.name = val,
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(labelText: "Sowing Date"),
                                      controller: TextEditingController(text: crop.sowingDate.split('T')[0]),
                                      readOnly: true,
                                      onTap: () async {
                                         FocusScope.of(context).requestFocus(FocusNode());
                                         DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.tryParse(crop.sowingDate) ?? DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2030),
                                        );
                                        if(picked != null) {
                                          setState(() {
                                            crop.sowingDate = picked.toIso8601String();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(labelText: "Harvest Date"),
                                      controller: TextEditingController(text: crop.harvestDate.split('T')[0]),
                                      readOnly: true,
                                      onTap: () async {
                                         FocusScope.of(context).requestFocus(FocusNode());
                                         DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.tryParse(crop.harvestDate) ?? DateTime.now().add(const Duration(days: 90)),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2030),
                                        );
                                        if(picked != null) {
                                          setState(() {
                                            crop.harvestDate = picked.toIso8601String();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveField,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('SAVE FIELD',
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
