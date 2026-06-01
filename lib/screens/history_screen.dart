// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/detection_service.dart';
import '../models/detection_result.dart';
import '../utils/app_theme.dart';
import 'result_screen.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filterSeverity = 'All';
  final List<String> _filters = ['All', 'Low', 'Moderate', 'High', 'Critical'];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final svc = context.read<DetectionService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Scan History')),
      backgroundColor: AppTheme.bgLight,
      body: Column(
        children: [
          // ── Severity filter chips ────────────────────────────────────
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final selected = _filterSeverity == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _filterSeverity = f),
                      selectedColor:
                          AppTheme.primaryGreen.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryGreen,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── History list ─────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<DetectionResult>>(
              stream: svc.historyStream(uid),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_outlined,
                            size: 72, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No scan history yet',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                var results = snap.data!;
                if (_filterSeverity != 'All') {
                  results = results
                      .where((r) =>
                          r.severity.toLowerCase() ==
                          _filterSeverity.toLowerCase())
                      .toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: results.length,
                  itemBuilder: (ctx, i) {
                    final r = results[i];
                    return _HistoryCard(result: r);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final DetectionResult result;
  const _HistoryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final sColor = severityColor(result.severity);
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(result.detectedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: result.imageUrl.isNotEmpty
                    ? Image.network(result.imageUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                              width: 72,
                              height: 72,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            ))
                    : Container(
                        width: 72,
                        height: 72,
                        color: sColor.withOpacity(0.15),
                        child: Icon(Icons.eco_rounded, color: sColor, size: 36),
                      ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.diseaseName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(result.cropType,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: sColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            result.severity.toUpperCase(),
                            style: TextStyle(
                                color: sColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                            '${(result.confidenceScore * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
