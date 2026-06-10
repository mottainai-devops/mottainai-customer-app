import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    if (profile != null) {
      _nameController.text = profile['fullName'] ?? '';
      _emailController.text = profile['email'] ?? '';
      _addressController.text = profile['address'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final result = await ApiService.updateProfile({
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
      });
      if (!mounted) return;
      if (result['success'] == true) {
        await context.read<AuthProvider>().refreshProfile();
        setState(() => _editing = false);
        _showSnack('Profile updated successfully');
      } else {
        _showSnack(result['message'] ?? 'Failed to update profile');
      }
    } catch (_) {
      _showSnack('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) context.go('/login');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final name = profile?['fullName'] ?? profile?['phone'] ?? 'Customer';
    final phone = profile?['phone'] ?? '—';
    final buildingIds = profile?['buildingIds'] as List? ?? [];
    // ArcGIS-native Customer IDs: arcgisBuildingId + unitCode composite (v3.5.0)
    // Falls back to buildingIds if customerIds not yet returned by backend
    final customerIds = profile?['customerIds'] as List? ?? buildingIds;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title:
            const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            )
          else
            TextButton(
              onPressed: () => setState(() => _editing = false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFF1B5E20),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'C',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A))),
                Text(phone,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Editable fields
          _sectionCard(
            title: 'Personal Information',
            children: [
              _fieldRow(
                label: 'Full Name',
                controller: _nameController,
                enabled: _editing,
                hint: 'Enter your full name',
              ),
              const SizedBox(height: 14),
              _fieldRow(
                label: 'Email',
                controller: _emailController,
                enabled: _editing,
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _fieldRow(
                label: 'Address',
                controller: _addressController,
                enabled: _editing,
                hint: 'Enter your address',
                maxLines: 2,
              ),
            ],
          ),

          if (_editing) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Customer ID(s) — ArcGIS-native composite (arcgisBuildingId + unitCode)
          if (customerIds.isNotEmpty)
            _sectionCard(
              title: customerIds.length == 1 ? 'Customer ID' : 'Customer IDs',
              children: [
                ...customerIds.map((cid) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined,
                          size: 18, color: Color(0xFF1B5E20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cid.toString(),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 4),
                Text(
                  'Use this ID when contacting support or referencing your account.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // My Properties
          if (buildingIds.isNotEmpty)
            _sectionCard(
              title: 'My Properties',
              children: buildingIds
                  .map((id) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.business_outlined,
                                size: 16, color: Color(0xFF1B5E20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(id.toString(),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),

          const SizedBox(height: 16),

          // Actions
          _sectionCard(
            title: 'Account',
            children: [
              _actionTile(
                icon: Icons.support_agent_outlined,
                label: 'Support',
                onTap: () => context.push('/support'),
              ),
              const Divider(height: 1),
              _actionTile(
                icon: Icons.logout,
                label: 'Sign Out',
                color: Colors.red,
                onTap: _confirmLogout,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 3),
    );
  }

  Widget _sectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1B5E20))),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _fieldRow({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600])),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor:
                enabled ? const Color(0xFFF5F5F5) : const Color(0xFFFAFAFA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? const Color(0xFF1B5E20), size: 22),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color ?? const Color(0xFF1A1A1A))),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}

Widget _buildBottomNav(BuildContext context, int currentIndex) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) {
        switch (i) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/pickups');
            break;
          case 2:
            context.go('/invoices');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF1B5E20),
      unselectedItemColor: Colors.grey[400],
      selectedFontSize: 11,
      unselectedFontSize: 11,
      elevation: 0,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Pickups'),
        BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Invoices'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile'),
      ],
    ),
  );
}
