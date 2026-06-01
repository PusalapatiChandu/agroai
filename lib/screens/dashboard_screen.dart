// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../models/detection_result.dart';
import 'result_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          // ── App bar with greeting ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('farmers')
                              .doc(uid)
                              .snapshots(),
                          builder: (ctx, snap) {
                            final name = snap.hasData && snap.data!.exists
                                ? (snap.data!.data()
                                        as Map<String, dynamic>)['name'] ??
                                    'Farmer'
                                : 'Farmer';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Good day, $name! 👋',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                                const Text(
                                  'How are your crops today?',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Stats row ────────────────────────────────────────────
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('detections')
                      .where('userId', isEqualTo: uid)
                      .snapshots(),
                  builder: (ctx, snap) {
                    final docs = snap.data?.docs ?? [];
                    final total = docs.length;
                    final critical = docs
                        .where((d) =>
                            (d.data() as Map)['severity'] == 'critical')
                        .length;
                    final healthy = docs
                        .where((d) =>
                            (d.data() as Map)['diseaseName'] == 'Healthy')
                        .length;
                    return Row(
                      children: [
                        _StatCard('Total Scans', '$total', Icons.qr_code_scanner,
                            AppTheme.skyBlue),
                        const SizedBox(width: 12),
                        _StatCard('Critical', '$critical',
                            Icons.warning_amber_rounded, AppTheme.dangerRed),
                        const SizedBox(width: 12),
                        _StatCard(
                            'Healthy', '$healthy', Icons.check_circle_outline,
                            AppTheme.lightGreen),
                      ],
                    );
                  },
                ).animate().slideY(begin: 0.3, duration: 400.ms).fade(),
                const SizedBox(height: 20),

                // ── Recent detections ─────────────────────────────────────
                const Text('Recent Scans',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('detections')
                      .where('userId', isEqualTo: uid)
                      .orderBy('detectedAt', descending: true)
                      .limit(5)
                      .snapshots(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return _EmptyState();
                    }
                    return Column(
                      children: docs.asMap().entries.map((entry) {
                        final result =
                            DetectionResult.fromFirestore(entry.value);
                        return _RecentCard(result: result)
                            .animate()
                            .slideX(
                                begin: 0.3,
                                delay: Duration(milliseconds: entry.key * 80))
                            .fade();
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ── Disease Tips ──────────────────────────────────────────
                const Text('Seasonal Disease Alerts 🌦',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _TipCard(
                  title: 'Rice Blast Alert',
                  body:
                      'High humidity this week increases blast risk. Spray tricyclazole preventively.',
                  icon: Icons.water_drop_outlined,
                  color: AppTheme.skyBlue,
                ),
                _TipCard(
                  title: 'Tomato Late Blight',
                  body:
                      'Cool nights + warm days — ideal for blight. Inspect leaves daily.',
                  icon: Icons.thermostat_outlined,
                  color: AppTheme.accentAmber,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subwidgets ──────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 6),
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.result});
  final DetectionResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              severityColor(result.severity).withOpacity(0.15),
          child: Text(severityEmoji(result.severity),
              style: const TextStyle(fontSize: 20)),
        ),
        title: Text(result.diseaseName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${result.cropType} · ${result.severity.toUpperCase()}'),
        trailing: Text(
            '${(result.confidenceScore * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ResultScreen(result: result)),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard(
      {required this.title,
      required this.body,
      required this.icon,
      required this.color});
  final String title, body;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(body, style: const TextStyle(fontSize: 12)),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.camera_alt_outlined,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No scans yet. Tap Scan to get started!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
}
