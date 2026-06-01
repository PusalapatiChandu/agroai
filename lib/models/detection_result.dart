// lib/models/detection_result.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DetectionResult {
  final String id;
  final String userId;
  final String cropType;
  final String diseaseName;
  final String severity;          // low / moderate / high / critical
  final double confidenceScore;   // 0.0 – 1.0
  final double severityPercent;   // leaf-area affected %
  final String imageUrl;
  final String description;
  final List<String> symptoms;
  final List<String> treatments;
  final List<String> preventions;
  final String weatherNote;
  final DateTime detectedAt;

  DetectionResult({
    required this.id,
    required this.userId,
    required this.cropType,
    required this.diseaseName,
    required this.severity,
    required this.confidenceScore,
    required this.severityPercent,
    required this.imageUrl,
    required this.description,
    required this.symptoms,
    required this.treatments,
    required this.preventions,
    required this.weatherNote,
    required this.detectedAt,
  });

  factory DetectionResult.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DetectionResult(
      id: doc.id,
      userId: d['userId'] ?? '',
      cropType: d['cropType'] ?? '',
      diseaseName: d['diseaseName'] ?? '',
      severity: d['severity'] ?? 'low',
      confidenceScore: (d['confidenceScore'] ?? 0).toDouble(),
      severityPercent: (d['severityPercent'] ?? 0).toDouble(),
      imageUrl: d['imageUrl'] ?? '',
      description: d['description'] ?? '',
      symptoms: List<String>.from(d['symptoms'] ?? []),
      treatments: List<String>.from(d['treatments'] ?? []),
      preventions: List<String>.from(d['preventions'] ?? []),
      weatherNote: d['weatherNote'] ?? '',
      detectedAt: (d['detectedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'cropType': cropType,
    'diseaseName': diseaseName,
    'severity': severity,
    'confidenceScore': confidenceScore,
    'severityPercent': severityPercent,
    'imageUrl': imageUrl,
    'description': description,
    'symptoms': symptoms,
    'treatments': treatments,
    'preventions': preventions,
    'weatherNote': weatherNote,
    'detectedAt': Timestamp.fromDate(detectedAt),
  };
}

// lib/models/farmer_profile.dart (inline for brevity)
class FarmerProfile {
  final String uid;
  final String name;
  final String phone;
  final String location;
  final String farmSize;
  final List<String> mainCrops;
  final int totalScans;
  final DateTime joinedAt;

  FarmerProfile({
    required this.uid,
    required this.name,
    required this.phone,
    required this.location,
    required this.farmSize,
    required this.mainCrops,
    required this.totalScans,
    required this.joinedAt,
  });

  factory FarmerProfile.fromMap(Map<String, dynamic> d) => FarmerProfile(
    uid: d['uid'] ?? '',
    name: d['name'] ?? '',
    phone: d['phone'] ?? '',
    location: d['location'] ?? '',
    farmSize: d['farmSize'] ?? '',
    mainCrops: List<String>.from(d['mainCrops'] ?? []),
    totalScans: d['totalScans'] ?? 0,
    joinedAt: d['joinedAt'] != null
        ? (d['joinedAt'] as dynamic).toDate()
        : DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'phone': phone,
    'location': location,
    'farmSize': farmSize,
    'mainCrops': mainCrops,
    'totalScans': totalScans,
    'joinedAt': joinedAt,
  };
}

// lib/models/chat_message.dart (inline)
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}
