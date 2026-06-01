import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/detection_service.dart';
import '../utils/app_theme.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  Uint8List? _imageBytes;
  String? _imagePath; // For mobile preview
  String _selectedCrop = 'Auto-detect';
  bool _isDetecting = false;
  String? _detectedCrop;
  final ImagePicker _picker = ImagePicker();

  final List<String> _crops = [
    'Auto-detect', 'Rice', 'Wheat', 'Tomato', 'Potato', 'Maize', 'Cotton',
    'Sugarcane', 'Groundnut', 'Soybean', 'Banana', 'Mango', 'Other'
  ];

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xFile != null) {
      final bytes = await xFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imagePath = xFile.path;
        _isDetecting = true;
        _detectedCrop = null;
      });

      // Automatically identify crop after pick
      try {
        final svc = context.read<DetectionService>();
        final detected = await svc.identifyCrop(bytes);
        if (mounted) {
          setState(() {
            _detectedCrop = detected;
            _isDetecting = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isDetecting = false);
      }
    }
  }

  Future<void> _analyze() async {
    if (_imageBytes == null) return;
    final svc = context.read<DetectionService>();
    final result = await svc.analyzeImage(_imageBytes!, _selectedCrop);
    if (result != null && mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ResultScreen(result: result)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DetectionService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Crop Leaf')),
      backgroundColor: AppTheme.bgLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image preview area ───────────────────────────────────────
            GestureDetector(
              onTap: () => _showPickerSheet(),
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.4), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: kIsWeb 
                          ? Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity)
                          : Image.file(File(_imagePath!), fit: BoxFit.cover, width: double.infinity))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 64,
                              color: AppTheme.primaryGreen.withOpacity(0.6)),
                          const SizedBox(height: 12),
                          const Text('Tap to capture or upload leaf image',
                              style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 6),
                          const Text('JPG / PNG supported',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            if (_isDetecting)
              const LinearProgressIndicator(color: AppTheme.primaryGreen)
            else if (_detectedCrop != null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Text('Detected Item: $_detectedCrop', 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // ── Action buttons ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      foregroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      foregroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Crop selector ────────────────────────────────────────────
            const Text('Select Crop Type',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCrop,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.grass_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _crops
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCrop = v!),
            ),
            const SizedBox(height: 32),

            // ── Tips ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.25)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📸 Tips for best results',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('• Photograph a single leaf clearly'),
                  Text('• Ensure good natural lighting'),
                  Text('• Include the affected area in frame'),
                  Text('• Avoid blurry or dark images'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Analyze button ───────────────────────────────────────────
            if (svc.isAnalyzing) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              Center(
                child: Text(svc.status,
                    style: const TextStyle(color: AppTheme.primaryGreen)),
              ),
            ] else
              ElevatedButton.icon(
                icon: const Icon(Icons.biotech_outlined),
                label: Text(_selectedCrop == 'Auto-detect' ? 'Identify & Analyze' : 'Analyze Disease'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _imageBytes != null
                      ? AppTheme.primaryGreen
                      : Colors.grey,
                ),
                onPressed: _imageBytes != null ? _analyze : null,
              ),
          ],
        ),
      ),
    );
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
