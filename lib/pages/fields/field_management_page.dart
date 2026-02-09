import 'package:flutter/material.dart';
import '../../services/field_service.dart';
import '../../models/field_model.dart';
import 'add_edit_field_page.dart';
import '../dashboard/dashboard_layout.dart';

class FieldManagementPage extends StatefulWidget {
  const FieldManagementPage({super.key});

  @override
  State<FieldManagementPage> createState() => _FieldManagementPageState();
}

class _FieldManagementPageState extends State<FieldManagementPage> {
  final FieldService _fieldService = FieldService();
  List<Field> _fields = [];
  bool _isAddingOrEditing = false;
  Field? _selectedField;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    await _fieldService.loadFields();
    setState(() {
      _fields = _fieldService.getFields();
    });
  }

  void _navigateToAddField() {
    setState(() {
      _isAddingOrEditing = true;
      _selectedField = null;
    });
  }

  void _navigateToEditField(Field field) {
    setState(() {
      _isAddingOrEditing = true;
      _selectedField = field;
    });
  }

  void _closeAddEdit() {
    setState(() {
      _isAddingOrEditing = false;
      _selectedField = null;
    });
    _loadFields(); // Refresh list
  }
  
  void _deleteField(String id) async {
    await _fieldService.deleteField(id);
    _loadFields();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Field deleted')));
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    
    if (_isAddingOrEditing) {
      content = AddEditFieldPage(
        field: _selectedField,
        onFinished: _closeAddEdit,
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Fields',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF2D5F2E),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              ElevatedButton.icon(
                onPressed: _navigateToAddField,
                icon: const Icon(Icons.add),
                label: const Text('Add New Field'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _fields.isEmpty
                ? const Center(child: Text('No fields added yet.'))
                : ListView.builder(
                    itemCount: _fields.length,
                    itemBuilder: (context, index) {
                      final field = _fields[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                         elevation: 2,
                        child: ListTile(
                          title: Text(field.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${field.crops.length} Crops | ${field.boundary.length} Points'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _navigateToEditField(field),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => showDialog(
                                  context: context, 
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Delete Field"),
                                    content: Text("Are you sure you want to delete ${field.name}?"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                      TextButton(onPressed: () {
                                          Navigator.pop(ctx);
                                          _deleteField(field.id);
                                      }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                    ],
                                  )
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return DashboardLayout(
      currentPage: 'Fields',
      enableScrolling: false,
      child: content,
    );
  }
}
