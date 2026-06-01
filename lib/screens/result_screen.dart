// lib/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/detection_result.dart';
import '../utils/app_theme.dart';

class ResultScreen extends StatelessWidget {
  final DetectionResult result;
  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final sColor = severityColor(result.severity);
    final sEmoji = severityEmoji(result.severity);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          // ── Hero image header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(result.diseaseName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              background: result.imageUrl.isNotEmpty
                  ? Image.network(result.imageUrl, fit: BoxFit.cover)
                  : Container(color: AppTheme.primaryGreen),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Severity badge ─────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sColor),
                      ),
                      child: Text('$sEmoji  ${result.severity.toUpperCase()}',
                          style: TextStyle(
                              color: sColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.skyBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: AppTheme.skyBlue.withOpacity(0.4)),
                      ),
                      child: Text(
                          '${result.cropType} · ${(result.confidenceScore * 100).toStringAsFixed(1)}% confident',
                          style: const TextStyle(
                              color: AppTheme.skyBlue, fontSize: 12)),
                    ),
                  ],
                ).animate().fade(duration: 400.ms),
                const SizedBox(height: 20),

                // ── Severity gauge ─────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Leaf Area Affected',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        Center(
                          child: CircularPercentIndicator(
                            radius: 80,
                            lineWidth: 14,
                            percent: result.severityPercent / 100,
                            center: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    '${result.severityPercent.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: sColor)),
                                const Text('affected',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            progressColor: sColor,
                            backgroundColor: sColor.withOpacity(0.1),
                            circularStrokeCap: CircularStrokeCap.round,
                            animation: true,
                            animationDuration: 1200,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 0.2, duration: 500.ms).fade(),
                const SizedBox(height: 16),

                // ── Description ────────────────────────────────────────
                _SectionCard(
                  title: '🔬 About this Disease',
                  child: Text(result.description,
                      style: const TextStyle(
                          fontSize: 14, height: 1.6, color: Colors.black87)),
                ),
                const SizedBox(height: 12),

                // ── Symptoms ───────────────────────────────────────────
                _SectionCard(
                  title: '🩺 Observed Symptoms',
                  child: _BulletList(items: result.symptoms),
                ),
                const SizedBox(height: 12),

                // ── Treatments ─────────────────────────────────────────
                _SectionCard(
                  title: '💊 Recommended Treatments',
                  child: _NumberedList(items: result.treatments),
                ),
                const SizedBox(height: 12),

                // ── Prevention ─────────────────────────────────────────
                _SectionCard(
                  title: '🛡️ Preventive Measures',
                  child: _BulletList(items: result.preventions),
                ),
                const SizedBox(height: 12),

                // ── Weather note ───────────────────────────────────────
                if (result.weatherNote.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.skyBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.skyBlue.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🌦 ', style: TextStyle(fontSize: 20)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Weather Impact',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(result.weatherNote,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black87)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // ── Share / Save button ────────────────────────────────
                ElevatedButton.icon(
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share Result'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share feature coming soon!')),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ).animate().slideY(begin: 0.15, duration: 400.ms).fade();
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Expanded(
                          child: Text(item,
                              style: const TextStyle(
                                  fontSize: 13, height: 1.5))),
                    ],
                  ),
                ))
            .toList(),
      );
}

class _NumberedList extends StatelessWidget {
  final List<String> items;
  const _NumberedList({required this.items});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text('${e.key + 1}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11)),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(e.value,
                        style:
                            const TextStyle(fontSize: 13, height: 1.5))),
              ],
            ),
          );
        }).toList(),
      );
}
