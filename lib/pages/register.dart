import 'package:flutter/material.dart';
import 'package:agrinetra/widgets/map.dart';
import 'package:latlong2/latlong.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  // Form Key for validation
  final _formKey = GlobalKey<FormState>();

  // Cultivation Status Variables
  bool _isCultivating = false;
  bool _hasMultipleCrops = false;
  String _cropIntegrationType =
      'Integrated'; // Options: 'Integrated', 'Separated'

  // List to hold details for multiple crops
  List<Map<String, String>> _cropDetails = [
    {'cropName': '', 'sowingDate': '', 'harvestDate': ''},
  ];
  List<LatLng> _landBoundary = [];

  // Placeholder function for map drawing/data
  void _openMapForBoundaryDrawing() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                const MapDrawingScreen(title: "Draw Main Land Boundary"),
      ),
    );

    if (result != null && result is List<LatLng>) {
      setState(() {
        _landBoundary = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Main boundary saved with ${_landBoundary.length} points!',
          ),
        ),
      );
    }
  }

  void _openMapForSubPlotDrawing(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                MapDrawingScreen(title: "Draw Boundary for Crop ${index + 1}"),
      ),
    );

    if (result != null && result is List<LatLng>) {
      // TODO: You would store the result in a more complex state structure
      // that associates the boundary with the specific crop in _cropDetails list.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Crop ${index + 1} sub-boundary saved with ${result.length} points!',
          ),
        ),
      );
    }
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // TODO: Implement registration logic, send data to backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration Data Collected!')),
      );
      // Example navigation after successful registration
      // Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Register for Agrinetra"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Form(
            key: _formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Account Details ---
                  Text("Account Setup", style: theme.textTheme.headlineSmall),
                  const Divider(),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Email",
                      hintText: "farmer@example.com",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Please enter your email.'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      hintText: "••••••••",
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty || value.length < 8
                                ? 'Password must be at least 8 characters.'
                                : null,
                    onSaved:
                        (value) => print(
                          'Password saved',
                        ), // Don't actually save in real app
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirm Password",
                      hintText: "••••••••",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      // This validation is simplified. In a real app, you'd need
                      // access to the main password field's value.
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // --- Land Boundary Mapping ---
                  Text(
                    "Land Boundary Mapping",
                    style: theme.textTheme.headlineSmall,
                  ),
                  const Divider(),
                  const Text(
                    "Use the map tool to draw the boundary of your land (multiple disconnected plots are allowed).",
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openMapForBoundaryDrawing,
                      icon: Icon(
                        _landBoundary.isEmpty
                            ? Icons.map
                            : Icons.edit_location_alt,
                      ),
                      label: Text(
                        _landBoundary.isEmpty
                            ? "Draw Land Boundary on Map"
                            : "Boundary Set (${_landBoundary.length} points). Tap to Edit.",
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor:
                            _landBoundary.isEmpty
                                ? theme.colorScheme.primary
                                : Colors.green.shade600,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Cultivation Status ---
                  Text(
                    "Cultivation Status",
                    style: theme.textTheme.headlineSmall,
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Text("Is the land currently being cultivated?"),
                      const Spacer(),
                      Switch(
                        value: _isCultivating,
                        onChanged: (bool value) {
                          setState(() {
                            _isCultivating = value;
                            if (!value) {
                              _hasMultipleCrops = false;
                              _cropDetails = [
                                {
                                  'cropName': '',
                                  'sowingDate': '',
                                  'harvestDate': '',
                                },
                              ];
                            }
                          });
                        },
                      ),
                    ],
                  ),

                  // --- Conditional Cultivation Details ---
                  if (_isCultivating) ...[
                    const SizedBox(height: 16),
                    // Multiple Crops
                    Row(
                      children: [
                        const Text("Are multiple crops present?"),
                        const Spacer(),
                        Switch(
                          value: _hasMultipleCrops,
                          onChanged: (bool value) {
                            setState(() {
                              _hasMultipleCrops = value;
                              if (value) {
                                // Ensure at least two crop entries when multiple is selected
                                if (_cropDetails.length < 2) {
                                  _cropDetails.add({
                                    'cropName': '',
                                    'sowingDate': '',
                                    'harvestDate': '',
                                  });
                                }
                              } else {
                                // Reset to a single crop entry
                                _cropDetails = [
                                  {
                                    'cropName': '',
                                    'sowingDate': '',
                                    'harvestDate': '',
                                  },
                                ];
                              }
                            });
                          },
                        ),
                      ],
                    ),

                    // Crop Integration (Conditional)
                    if (_hasMultipleCrops) ...[
                      const SizedBox(height: 16),
                      const Text("Are the crops integrated or separated?"),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Integrated'),
                              value: 'Integrated',
                              groupValue: _cropIntegrationType,
                              onChanged: (String? value) {
                                setState(() {
                                  _cropIntegrationType = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Separated'),
                              value: 'Separated',
                              groupValue: _cropIntegrationType,
                              onChanged: (String? value) {
                                setState(() {
                                  _cropIntegrationType = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    // --- Crop Details and Schedule (Repeatable) ---
                    const SizedBox(height: 24),
                    Text(
                      "Crop Details and Schedule",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ..._cropDetails.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, String> cropData = entry.value;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Crop Plot ${index + 1}",
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              if (_hasMultipleCrops &&
                                  _cropIntegrationType == 'Separated')
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8.0,
                                    bottom: 8.0,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          () =>
                                              _openMapForSubPlotDrawing(index),
                                      icon: const Icon(Icons.crop_square),
                                      label: const Text(
                                        "Draw Cultivated Boundary",
                                      ),
                                    ),
                                  ),
                                ),
                              TextFormField(
                                initialValue: cropData['cropName'],
                                decoration: const InputDecoration(
                                  labelText: "Crop Name",
                                  hintText: "e.g., Rice, Maize",
                                ),
                                onChanged:
                                    (value) => cropData['cropName'] = value,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: cropData['sowingDate'],
                                decoration: const InputDecoration(
                                  labelText: "Sowing Date (YYYY-MM-DD)",
                                  hintText: "e.g., 2025-06-15",
                                ),
                                keyboardType: TextInputType.datetime,
                                onTap: () async {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(FocusNode());
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      cropData['sowingDate'] =
                                          picked.toString().split(' ')[0];
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: cropData['harvestDate'],
                                decoration: const InputDecoration(
                                  labelText:
                                      "Expected Harvest Date (YYYY-MM-DD)",
                                  hintText: "e.g., 2025-10-30",
                                ),
                                keyboardType: TextInputType.datetime,
                                onTap: () async {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(FocusNode());
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now().add(
                                      const Duration(days: 90),
                                    ),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      cropData['harvestDate'] =
                                          picked.toString().split(' ')[0];
                                    });
                                  }
                                },
                              ),
                              if (_hasMultipleCrops && _cropDetails.length > 1)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    label: const Text('Remove Crop'),
                                    onPressed: () {
                                      setState(() {
                                        _cropDetails.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    if (_hasMultipleCrops)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Another Crop'),
                          onPressed: () {
                            setState(() {
                              _cropDetails.add({
                                'cropName': '',
                                'sowingDate': '',
                                'harvestDate': '',
                              });
                            });
                          },
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],

                  // --- Register Button ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: const Text("Register Account"),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Go back to the login page
                      },
                      child: const Text("Already have an account? Login"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
