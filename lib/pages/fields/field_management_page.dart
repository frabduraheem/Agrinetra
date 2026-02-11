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
  bool _isLoading = true;
  bool _hasError = false;
  
  List<Field> _fields = [];
  bool _isAddingOrEditing = false;
  Field? _selectedField;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    bool success = await _fieldService.fetchFieldsFromBackend();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _fields = _fieldService.getFields();
        } else {
          _hasError = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to fetch fields from server')),
          );
        }
      });
    }
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
    // We can reload from local state since add/edit updates it on success
    setState(() {
       _fields = _fieldService.getFields();
    });
  }
  
  void _deleteField(String id) async {
    // Show loading or just wait? Better to show visual feedback.
    // Since we are in a dialog, we pop it first in the builder then call this.
    // Let's show a loading snackbar or just await.
    
    String? error = await _fieldService.deleteField(id);
    
    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Field deleted successfully')),
        );
        setState(() {
           _fields = _fieldService.getFields();
        });
      }
    }
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
      if (_isLoading) {
        content = const Center(child: CircularProgressIndicator());
      } else if (_hasError) {
        content = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load fields.', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadFields,
                child: const Text('Retry'),
              )
            ],
          ),
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
    }

    return DashboardLayout(
      currentPage: 'Fields',
      enableScrolling: false,
      child: content,
    );
  }
}
