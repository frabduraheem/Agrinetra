import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_page.dart';
import 'soil_health/soil_health_page.dart';
import 'crop_health/crop_health_page.dart';
import 'green_credits/green_credits_page.dart';
import 'irrigation/irrigation_page.dart';
import 'settings/settings_page.dart';

import '../fields/field_management_page.dart';

class DashboardLayout extends StatefulWidget {
  final Widget child;
  final String currentPage;
  final bool enableScrolling;

  const DashboardLayout({
    required this.child,
    this.currentPage = 'Dashboard',
    this.enableScrolling = true,
    super.key,
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchResults = false;
  List<Map<String, dynamic>> _searchResults = [];

  final List<Map<String, dynamic>> _allFeatures = [
    {'name': 'Dashboard', 'icon': Icons.dashboard, 'page': 'Dashboard'},
    {'name': 'Fields', 'icon': Icons.grid_on, 'page': 'Fields'}, // Added Fields
    {'name': 'Crop Health', 'icon': Icons.local_florist, 'page': 'Crop Health'},
    {'name': 'NDVI Map', 'icon': Icons.map, 'page': 'Crop Health'},
    {'name': 'Irrigation', 'icon': Icons.water_drop, 'page': 'Irrigation'},
    {
      'name': 'Irrigation Schedule',
      'icon': Icons.schedule,
      'page': 'Irrigation',
    },
    {'name': 'Soil Health', 'icon': Icons.terrain, 'page': 'Soil Health'},
    {'name': 'Soil Moisture', 'icon': Icons.water, 'page': 'Soil Health'},
    {'name': 'Green Credits', 'icon': Icons.eco, 'page': 'Green Credits'},
    {'name': 'Badges', 'icon': Icons.emoji_events, 'page': 'Green Credits'},
    {'name': 'Settings', 'icon': Icons.settings, 'page': 'Settings'},
    {'name': 'Account', 'icon': Icons.account_circle, 'page': 'Settings'},
  ];

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searchResults = _allFeatures
          .where(
            (feature) => feature['name'].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
      _showSearchResults = true;
    });
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _navigateToPage(BuildContext context, String page) {
    // Close search if open
    setState(() {
      _showSearchResults = false;
      _searchController.clear();
    });

    // Don't navigate if we're already on this page
    if (page == widget.currentPage) {
      return;
    }

    Widget destination;
    switch (page) {
      case 'Dashboard':
        destination = const DashboardPage();
        break;
      case 'Fields':
        destination = const FieldManagementPage();
        break;
      case 'Crop Health':
        destination = const CropHealthPage();
        break;
      case 'Irrigation':
        destination = const IrrigationPage();
        break;
      case 'Soil Health':
        destination = const SoilHealthPage();
        break;
      case 'Green Credits':
        destination = const GreenCreditsPage();
        break;
      case 'Settings':
        destination = const SettingsPage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1E8),
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar
              Container(
                width: 256,
                color: const Color(0xFFD4E7D4),
                child: Column(
                  children: [
                    // Logo Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.eco, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Agrinetra',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D5F2E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Navigation Items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          _navItem(
                            context,
                            Icons.dashboard,
                            'Dashboard',
                            widget.currentPage == 'Dashboard',
                          ),
                          _navItem(
                            context,
                            Icons.grid_on,
                            'Fields',
                            widget.currentPage == 'Fields',
                          ),
                          _navItem(
                            context,
                            Icons.local_florist,
                            'Crop Health',
                            widget.currentPage == 'Crop Health',
                          ),
                          _navItem(
                            context,
                            Icons.water_drop,
                            'Irrigation',
                            widget.currentPage == 'Irrigation',
                          ),
                          _navItem(
                            context,
                            Icons.terrain,
                            'Soil Health',
                            widget.currentPage == 'Soil Health',
                          ),
                          _navItem(
                            context,
                            Icons.eco,
                            'Green Credits',
                            widget.currentPage == 'Green Credits',
                          ),
                        ],
                      ),
                    ),
                    // Settings and Support at bottom
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          _navItem(
                            context,
                            Icons.settings,
                            'Settings',
                            widget.currentPage == 'Settings',
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.support,
                              color: Color(0xFF2D5F2E),
                            ),
                            title: const Text(
                              'Support',
                              style: TextStyle(color: Color(0xFF2D5F2E)),
                            ),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Support: Call 1800-XXX-XXXX'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Column(
                  children: [
                    // Top App Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Search features...',
                                  border: InputBorder.none,
                                  icon: Icon(Icons.search, color: Colors.grey),
                                ),
                                onChanged: _performSearch,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF4CAF50),
                            child: IconButton(
                              icon: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () => _logout(context),
                              padding: EdgeInsets.zero,
                              tooltip: 'Logout',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Page Content
                    Expanded(
                      child: widget.enableScrolling
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: widget.child,
                            )
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: widget.child,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Search Results Overlay
          if (_showSearchResults)
            Positioned(
              top: 72,
              left: 256 + 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _searchResults.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No results found for "${_searchController.text}"',
                          style: const TextStyle(color: Color(0xFF5F7D5F)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: Icon(
                              result['icon'] as IconData,
                              color: const Color(0xFF4CAF50),
                            ),
                            title: Text(
                              result['name'] as String,
                              style: const TextStyle(
                                color: Color(0xFF2D5F2E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () {
                              _navigateToPage(
                                context,
                                result['page'] as String,
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2D5F2E)),
        title: Text(
          label,
          style: TextStyle(
            color: const Color(0xFF2D5F2E),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => _navigateToPage(context, label),
      ),
    );
  }
}
