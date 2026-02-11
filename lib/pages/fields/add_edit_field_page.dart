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

class _UiCrop {
  Crop crop;
  String? originalName; // null if new, otherwise the name loaded from backend
  bool isNew;

  _UiCrop({required this.crop, this.originalName, this.isNew = false});
}

class _AddEditFieldPageState extends State<AddEditFieldPage> {
  final _formKey = GlobalKey<FormState>();
  final FieldService _fieldService = FieldService();
  
  late String _name;
  List<LatLng> _boundary = [];
  List<_UiCrop> _uiCrops = [];
  final List<String> _deletedCropNames = []; // Track crops to delete from backend
  
  List<String> _availableCrops = []; // Fetched from backend
  bool _isLoadingCrops = false;

  bool _isCultivated = false;

  bool _isEditing = false;
  String? _fieldId;

  @override
  void initState() {
    super.initState();
    _fetchCropTypes();

    _isEditing = widget.field != null;
    if (_isEditing) {
      _fieldId = widget.field!.id;
      _name = widget.field!.name;
      _boundary = List.from(widget.field!.boundary);
      // Map existing crops to UiCrops
      _uiCrops = widget.field!.crops.map((c) => _UiCrop(
        crop: Crop(name: c.name, plantingDate: c.plantingDate, harvestDate: c.harvestDate), // Deep copy
        originalName: c.name,
        isNew: false
      )).toList();
      _isCultivated = widget.field!.isCultivated;
    } else {
      _name = '';
      _isCultivated = false;
    }
  }

  Future<void> _fetchCropTypes() async {
     setState(() => _isLoadingCrops = true);
     final crops = await _fieldService.fetchAvailableCrops();
     if (mounted) {
       setState(() {
         _availableCrops = crops;
         _isLoadingCrops = false;
       });
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

  bool _isLoading = false;

  void _saveField() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_boundary.isEmpty || _boundary.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw a valid field boundary on the map.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Prepare Field Object (without crops first, we sync them separately usually, 
    //    but local model needs them for immediate UI update if we don't reload)
    //    Actually, FieldService.addField uses this object to add to local list.
    //    So we should populate it.
    
    final currentCrops = _uiCrops.map((u) => u.crop).toList();
    
    final newField = Field(
      id: _fieldId ?? const Uuid().v4(),
      name: _name,
      boundary: _boundary,
      crops: _isCultivated ? currentCrops : [],
      isCultivated: _isCultivated,
    );
    
    // 2. Save/Update Field (Plot)
    String? error;
    if (_isEditing) {
      error = await _fieldService.updateField(newField);
    } else {
      error = await _fieldService.addField(newField);
    }

    if (error != null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // 3. Sync Crops (If Field Saved Successfully)
    String? cropError = await _syncCrops(newField.id); // Debug prints removed

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (cropError != null) {
         showDialog(
           context: context,
           builder: (ctx) => AlertDialog(
             title: const Text("Crop Sync Failed"),
             content: Text("Field saved, but crops could not be saved.\n\nError: $cropError"),
             actions: [
               TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
             ],
           )
         );
      } else {
        widget.onFinished();
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(_isEditing ? 'Field and crops updated' : 'Field and crops added')),
        );
      }
    }
  }

  Future<String?> _syncCrops(String plotId) async {
    try {
      if (!_isCultivated) {
         // Logic to clear crops is handled by the toggle switch state change
      }

      // 1. Handle Deletions
      for (String name in _deletedCropNames) {
        String? err = await _fieldService.deleteCropFromBackend(plotId, name);
        if (err != null) return "Delete $name failed: $err";
      }

      // 2. Handle Adds and Edits
      for (var uiCrop in _uiCrops) {
        if (uiCrop.isNew) {
           String? err = await _fieldService.addCropToBackend(plotId, uiCrop.crop);
           if (err != null) return "Add ${uiCrop.crop.name} failed: $err";
        } else {
           // It's an existing crop, check if we need to edit
           // We always call edit for simplicity, or we could check dirty flags.
           // Since we don't have dirty flags easily, let's call edit.
           // Note: originalName must not be null here.
           String? err = await _fieldService.editCropInBackend(plotId, uiCrop.originalName!, uiCrop.crop);
           if (err != null) return "Update ${uiCrop.crop.name} failed: $err";
        }
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  void _addCrop() {
    setState(() {
      _uiCrops.add(_UiCrop(
        crop: Crop(
          name: '', // Initially empty, must submit via dropdown
          plantingDate: DateTime.now(), 
          harvestDate: DateTime.now().add(const Duration(days: 90))
        ),
        isNew: true
      ));
    });
  }

  void _removeCrop(int index) {
    setState(() {
      final removed = _uiCrops.removeAt(index);
      if (!removed.isNew && removed.originalName != null) {
        _deletedCropNames.add(removed.originalName!);
      }
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
                           // Remove all crops visually and mark for deletion
                           for (var c in _uiCrops) {
                             if (!c.isNew && c.originalName != null) {
                               _deletedCropNames.add(c.originalName!);
                             }
                           }
                           _uiCrops.clear(); 
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
                    if (_isLoadingCrops) 
                      const Center(child: CircularProgressIndicator())
                    else if (_uiCrops.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("No crops added."),
                      ),
                      
                    ..._uiCrops.asMap().entries.map((entry) {
                      int index = entry.key;
                      _UiCrop uiCrop = entry.value;
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
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return Autocomplete<String>(
                                    optionsBuilder: (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) {
                                        return const Iterable<String>.empty();
                                      }
                                      return _availableCrops.where((String option) {
                                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                                      });
                                    },
                                    onSelected: (String selection) {
                                      setState(() {
                                        uiCrop.crop.name = selection;
                                      });
                                    },
                                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                      // Initialize controller if it's empty but model has value (e.g. edit mode)
                                      if (textEditingController.text.isEmpty && uiCrop.crop.name.isNotEmpty) {
                                        textEditingController.text = uiCrop.crop.name;
                                      }
                                      return TextFormField(
                                        controller: textEditingController,
                                        focusNode: focusNode,
                                        decoration: const InputDecoration(labelText: "Crop Name (Type to search)"),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select a crop';
                                          }
                                          if (!_availableCrops.contains(value)) {
                                            return 'Select a valid crop from list';
                                          }
                                          // Duplicate check
                                          int count = _uiCrops.where((c) => c.crop.name == value).length;
                                          if (count > 1) {
                                            return 'Duplicate crop';
                                          }
                                          return null;
                                        },
                                        onChanged: (val) {
                                          uiCrop.crop.name = val;
                                        },
                                      );
                                    },
                                  );
                                }
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(labelText: "Sowing Date"),
                                      controller: TextEditingController(text: uiCrop.crop.plantingDate.toIso8601String().split('T')[0]),
                                      readOnly: true,
                                      onTap: () async {
                                         FocusScope.of(context).requestFocus(FocusNode());
                                         DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: uiCrop.crop.plantingDate,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2030),
                                        );
                                        if(picked != null) {
                                          setState(() {
                                            uiCrop.crop.plantingDate = picked;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(labelText: "Harvest Date"),
                                      controller: TextEditingController(text: uiCrop.crop.harvestDate.toIso8601String().split('T')[0]),
                                      readOnly: true,
                                      onTap: () async {
                                         FocusScope.of(context).requestFocus(FocusNode());
                                         DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: uiCrop.crop.harvestDate,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2030),
                                        );
                                        if(picked != null) {
                                          setState(() {
                                            uiCrop.crop.harvestDate = picked;
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
                      onPressed: _isLoading ? null : _saveField,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading 
                          ? const SizedBox(
                                height: 24, 
                                width: 24, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const Text('SAVE FIELD',
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
