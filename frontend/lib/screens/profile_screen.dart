import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _farmController = TextEditingController();
  String _selectedTown = "Tagbilaran City";
  bool _isSaving = false;

  final List<String> _towns = [
    "Tagbilaran City",
    "Ubay",
    "Carmen",
    "Jagna",
    "Talibon"
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? "Jeshua";
      _farmController.text = prefs.getString('farm_name') ?? "My Mango Farm";
      _selectedTown = prefs.getString('selected_town') ?? "Tagbilaran City";
    });
  }

  Future<void> _saveProfileData() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text);
    await prefs.setString('farm_name', _farmController.text);
    await prefs.setString('selected_town', _selectedTown);
    
    // Simulate a small delay for premium feel
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mangoBackground,
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: mangoText,
        actions: [
          IconButton(
            onPressed: _saveProfileData,
            icon: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check_circle_rounded, color: Colors.green),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Profile Header ---
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 20,
                        )
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/icon.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: mangoPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- Personal Info ---
            _buildSectionLabel("Personal Information"),
            const SizedBox(height: 16),
            _buildTextField("Full Name", _nameController, Icons.person_outline_rounded),
            const SizedBox(height: 16),
            _buildTextField("Farm Name", _farmController, Icons.agriculture_rounded),
            
            const SizedBox(height: 32),

            // --- Bohol Location Settings ---
            _buildSectionLabel("Bohol Market Settings"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: mangoSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: mangoBorder.withAlpha(30)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTown,
                  isExpanded: true,
                  icon: const Icon(Icons.location_on_rounded, color: Colors.red),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedTown = newValue);
                    }
                  },
                  items: _towns.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Text(
              "Selecting your town will auto-update market prices on your home screen.",
              style: TextStyle(fontSize: 11, color: Colors.black38),
            ),

            const SizedBox(height: 40),

            // --- Other Actions ---
            _buildSectionLabel("Account Actions"),
            const SizedBox(height: 16),
            _buildActionItem(Icons.security_rounded, "Privacy & Security"),
            _buildActionItem(Icons.help_center_rounded, "Bohol Mango Support"),
            _buildActionItem(Icons.logout_rounded, "Sign Out", Colors.red),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black45,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: mangoSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mangoBorder.withAlpha(30)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black45, fontSize: 14),
          prefixIcon: Icon(icon, color: mangoPrimary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, [Color? color]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: mangoSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? mangoPrimary, size: 22),
        title: Text(title, style: TextStyle(
          color: color ?? mangoText,
          fontSize: 15,
          fontWeight: FontWeight.w500
        )),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: () {},
      ),
    );
  }
}
