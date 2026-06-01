// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'auth/login_screen.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout')),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await context.read<AuthService>().logout();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      backgroundColor: AppTheme.bgLight,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('farmers')
            .doc(uid)
            .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? 'Farmer';
          final email = data['email'] ?? '';
          final phone = data['phone'] ?? '';
          final location = data['location'] ?? '';
          final totalScans = data['totalScans'] ?? 0;
          final crops = List<String>.from(data['mainCrops'] ?? []);
          final joined = data['joinedAt'] != null
              ? DateFormat('MMM yyyy')
                  .format((data['joinedAt'] as dynamic).toDate())
              : '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── Avatar & name ─────────────────────────────────────
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'F',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(color: Colors.grey)),
                if (joined.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Member since $joined',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ),
                const SizedBox(height: 20),

                // ── Stats row ─────────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem('$totalScans', 'Total Scans',
                            Icons.qr_code_scanner),
                        _Divider(),
                        _StatItem(
                            location.isNotEmpty
                                ? location.split(',')[0]
                                : '—',
                            'Location',
                            Icons.location_on_outlined),
                        _Divider(),
                        _StatItem(
                            '${crops.length}', 'Crops', Icons.grass_outlined),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Info card ─────────────────────────────────────────
                _InfoCard(label: 'Phone Number', value: phone, icon: Icons.phone_outlined),
                _InfoCard(label: 'Village / District', value: location, icon: Icons.location_on_outlined),
                _InfoCard(
                    label: 'Main Crops',
                    value: crops.isNotEmpty ? crops.join(', ') : 'Not set',
                    icon: Icons.eco_outlined),

                const SizedBox(height: 20),

                // ── Edit profile button ───────────────────────────────
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    foregroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showEditDialog(context, data),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> data) {
    final phoneCtrl =
        TextEditingController(text: data['phone'] ?? '');
    final locationCtrl =
        TextEditingController(text: data['location'] ?? '');
    final cropsCtrl =
        TextEditingController(text: (data['mainCrops'] as List?)?.join(', ') ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit Profile',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 10),
            TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                    labelText: 'Village / District')),
            const SizedBox(height: 10),
            TextField(
                controller: cropsCtrl,
                decoration: const InputDecoration(
                    labelText: 'Main Crops (comma separated)',
                    hintText: 'Rice, Wheat, Tomato')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return;
                final crops = cropsCtrl.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                await FirebaseFirestore.instance
                    .collection('farmers')
                    .doc(uid)
                    .update({
                  'phone': phoneCtrl.text.trim(),
                  'location': locationCtrl.text.trim(),
                  'mainCrops': crops,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _StatItem(this.value, this.label, this.icon);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 24),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 40, child: VerticalDivider());
}

class _InfoCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _InfoCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: Icon(icon, color: AppTheme.primaryGreen),
          title: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          subtitle: Text(value.isNotEmpty ? value : 'Not set',
              style: const TextStyle(
                  fontSize: 15, color: Colors.black87)),
        ),
      );
}
