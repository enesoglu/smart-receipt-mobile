import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'add_receipt.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isScanning = false;
  String? _scannedText;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _scannedText = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting image';
      });
    }
  }

  Future<void> _scanReceipt() async {
    if (_selectedImage == null) return;

    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    final response = await _apiService.scanReceipt(_selectedImage!);

    if (mounted) {
      setState(() {
        _isScanning = false;
        if (response.success && response.data != null) {
          _scannedText = response.data!['rawText'] ?? 'No text found';
        } else {
          _errorMessage = response.message ?? 'OCR processing failed';
        }
      });
    }
  }

  void _proceedToAddReceipt() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AddReceiptScreen(
          scannedText: _scannedText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8A84A), // Orange background like UI
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4A6CFA),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_empty, color: Colors.white, size: 20),
          ),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4A6CFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.image, color: Colors.white, size: 20),
            ),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            _selectedImage!,
                            fit: BoxFit.contain,
                          ),
                          if (_isScanning)
                            Container(
                              color: Colors.black.withOpacity(0.5),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(color: Colors.white),
                                    SizedBox(height: 16),
                                    Text(
                                      'Scanning receipt...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Take a photo of your receipt\nor select from gallery',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),

          // Scanned text preview
          if (_scannedText != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Text(
                  _scannedText!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),

          // Error message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 16),

          // Bottom controls
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF4A6CFA),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  _buildCircleButton(
                    icon: Icons.close,
                    onPressed: () => Navigator.pop(context),
                  ),

                  // Camera button
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.camera),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF4A6CFA),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Confirm/Scan button
                  _buildCircleButton(
                    icon: _scannedText != null ? Icons.arrow_forward : Icons.check,
                    onPressed: _selectedImage != null
                        ? (_scannedText != null ? _proceedToAddReceipt : _scanReceipt)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: onPressed != null ? Colors.white : Colors.white.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: onPressed != null ? Colors.white : Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}

