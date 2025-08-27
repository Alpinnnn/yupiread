import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class DocumentScannerScreen extends StatefulWidget {
  final Function(List<String>) onDocumentsScanned;
  final bool useGallery;

  const DocumentScannerScreen({
    super.key,
    required this.onDocumentsScanned,
    this.useGallery = false,
  });

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  bool _isLoading = false;
  List<String> _scannedImagePaths = [];

  @override
  void initState() {
    super.initState();
    // Auto-start scanning based on mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.useGallery) {
        _scanFromGallery();
      } else {
        _scanWithCamera();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.useGallery ? 'Scan dari Galeri' : 'Scan dari Kamera',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Memproses dokumen...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : const Center(
              child: Text(
                'Scanning selesai. Kembali ke galeri.',
                style: TextStyle(color: Colors.white),
              ),
            ),
    );
  }

  Widget _buildScannerOptions() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Header
          const Icon(
            Icons.document_scanner,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 24),
          const Text(
            'Scan Dokumen',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Deteksi otomatis tepi dokumen dan crop dengan presisi tinggi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 48),

          // Scan Options
          _buildScanOption(
            icon: Icons.camera_alt,
            title: 'Scan dengan Kamera',
            subtitle: 'Deteksi otomatis tepi dokumen secara real-time',
            onTap: _scanWithCamera,
          ),
          const SizedBox(height: 16),
          _buildScanOption(
            icon: Icons.photo_library,
            title: 'Pilih dari Galeri',
            subtitle: 'Crop dokumen dari foto yang sudah ada',
            onTap: _scanFromGallery,
          ),

          const SizedBox(height: 48),
          
          // Features info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_fix_high, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Auto Detection',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.crop, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Smart Cropping',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.high_quality, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'High Quality Output',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannedPreview() {
    return Column(
      children: [
        // Preview image
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_scannedImagePaths.first),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.white54,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Gagal memuat hasil scan',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _rescanDocument,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Scan Ulang',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    'Gunakan',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _scanWithCamera() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Use cunning document scanner
      List<String> pictures = await CunningDocumentScanner.getPictures() ?? [];
      
      if (pictures.isNotEmpty) {
        List<String> savedPaths = [];
        
        // Copy all scanned images to app directory
        for (int i = 0; i < pictures.length; i++) {
          String imagePath = path.join(
            (await getApplicationSupportDirectory()).path,
            "scanned_${DateTime.now().millisecondsSinceEpoch}_$i.jpeg",
          );
          
          await File(pictures[i]).copy(imagePath);
          savedPaths.add(imagePath);
        }
        
        setState(() {
          _scannedImagePaths = savedPaths;
        });
        
        // Return all scanned images
        Navigator.pop(context);
        widget.onDocumentsScanned(savedPaths);
      } else {
        _showErrorSnackBar('Tidak ada dokumen yang di-scan');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scanFromGallery() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Use cunning document scanner with gallery option
      List<String> pictures = await CunningDocumentScanner.getPictures(
        isGalleryImportAllowed: true,
      ) ?? [];
      
      if (pictures.isNotEmpty) {
        List<String> savedPaths = [];
        
        // Copy all scanned images to app directory
        for (int i = 0; i < pictures.length; i++) {
          String imagePath = path.join(
            (await getApplicationSupportDirectory()).path,
            "scanned_${DateTime.now().millisecondsSinceEpoch}_$i.jpeg",
          );
          
          await File(pictures[i]).copy(imagePath);
          savedPaths.add(imagePath);
        }
        
        setState(() {
          _scannedImagePaths = savedPaths;
        });
        
        // Return all scanned images
        Navigator.pop(context);
        widget.onDocumentsScanned(savedPaths);
      } else {
        _showErrorSnackBar('Tidak ada dokumen yang di-scan dari galeri');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _rescanDocument() {
    setState(() {
      _scannedImagePaths = [];
    });
  }

  void _showPermissionDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Izin $permissionType Diperlukan'),
        content: Text(
          'Aplikasi memerlukan akses $permissionType untuk melakukan scan dokumen. '
          'Silakan berikan izin di pengaturan aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }
}
