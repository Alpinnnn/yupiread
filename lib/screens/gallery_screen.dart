import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/photo_model.dart';
import '../services/data_service.dart';
import '../widgets/lazy_grid_view.dart';
import 'photo_view_screen.dart';
import 'document_scanner_screen.dart';
import 'photo_page_view_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final DataService _dataService = DataService.instance;
  List<String> _selectedTags = [];
  List<PhotoModel> _filteredPhotos = [];
  List<PhotoPageModel> _filteredPhotoPages = [];

  void initState() {
    super.initState();
    _updateFilteredPhotos();
  }


  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return 4; // 4 columns for very wide screens
    } else if (screenWidth > 800) {
      return 3; // 3 columns for wide screens
    } else {
      return 2; // 2 columns for mobile/tablet
    }
  }

  void _updateFilteredPhotos() {
    setState(() {
      _filteredPhotos = _dataService.getFilteredPhotos(_selectedTags);
      _filteredPhotoPages = _dataService.getFilteredPhotoPages(_selectedTags);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Galeri Foto',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_filteredPhotos.length + _filteredPhotoPages.length} foto catatan',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).cardTheme.shadowColor ?? Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Stack(
                            children: [
                              Icon(
                                Icons.filter_list,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              if (_selectedTags.isNotEmpty)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 12,
                                      minHeight: 12,
                                    ),
                                    child: Text(
                                      '${_selectedTags.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onPressed: _showFilterDialog,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(context),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount:
                      _filteredPhotos.length +
                      _filteredPhotoPages.length +
                      1, // +1 for add button
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildAddPhotoCard(context);
                    }

                    final adjustedIndex = index - 1;
                    if (adjustedIndex < _filteredPhotoPages.length) {
                      return _buildPhotoPageCard(
                        context,
                        _filteredPhotoPages[adjustedIndex],
                      );
                    } else {
                      final photoIndex =
                          adjustedIndex - _filteredPhotoPages.length;
                      return _buildPhotoCard(
                        context,
                        _filteredPhotos[photoIndex],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPhotoCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showAddPhotoBottomSheet(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).cardTheme.shadowColor ?? Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.add_a_photo,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tambah Foto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Catatan baru',
              style: TextStyle(
                fontSize: 12, 
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(BuildContext context, PhotoModel photo) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoViewScreen(photoId: photo.id),
          ),
        ).then((_) => _updateFilteredPhotos()); // Refresh when returning
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).cardTheme.shadowColor ?? Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.file(
                        File(photo.imagePath),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.grey[200],
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Gagal memuat',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      if (photo.tags.isNotEmpty)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              photo.tags.first,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    photo.timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPageCard(BuildContext context, PhotoPageModel photoPage) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PhotoPageViewScreen(photoPageId: photoPage.id),
          ),
        ).then((_) => _updateFilteredPhotos()); // Refresh when returning
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).cardTheme.shadowColor ?? Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.file(
                        File(photoPage.coverImagePath),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.grey[200],
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Gagal memuat',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      if (photoPage.tags.isNotEmpty)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              photoPage.tags.first,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.collections,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${photoPage.photoCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photoPage.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    photoPage.timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPhotoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tambah Foto Catatan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildBottomSheetOption(
                        icon: Icons.camera_alt,
                        title: 'Scan dari Kamera',
                        onTap: () {
                          Navigator.pop(context);
                          _scanFromCamera();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildBottomSheetOption(
                        icon: Icons.photo_library,
                        title: 'Scan dari Galeri',
                        onTap: () {
                          Navigator.pop(context);
                          _scanFromGallery();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }




  Future<void> _processSelectedImage(
    String imagePath,
    String defaultTitle,
  ) async {
    try {
      // Save image to app directory
      final savedPath = await _dataService.savePhotoFile(imagePath);
      _showTagSelectionDialog(defaultTitle, savedPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan foto: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showTagSelectionDialog(String title, String imagePath) {
    final TextEditingController titleController = TextEditingController(
      text: title,
    );
    final TextEditingController descriptionController = TextEditingController();
    List<String> selectedTags = [];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Tambah Foto Catatan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Judul Foto',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi (Opsional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Pilih Tag (Opsional):',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children:
                              _dataService.availableTags.map((tag) {
                                final isSelected = selectedTags.contains(tag);
                                return FilterChip(
                                  label: Text(tag),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setDialogState(() {
                                      if (selected) {
                                        selectedTags.add(tag);
                                      } else {
                                        selectedTags.remove(tag);
                                      }
                                    });
                                  },
                                  selectedColor: const Color(
                                    0xFF2563EB,
                                  ).withOpacity(0.2),
                                  checkmarkColor: const Color(0xFF2563EB),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Delete the saved image if user cancels
                        File(imagePath).delete().catchError((_) {});
                      },
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final photoTitle = titleController.text.trim();
                        final photoDescription =
                            descriptionController.text.trim();

                        if (photoTitle.isNotEmpty) {
                          _dataService.addPhoto(
                            title: photoTitle,
                            imagePath: imagePath,
                            tags: selectedTags,
                            description: photoDescription,
                          );
                          _updateFilteredPhotos();
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Foto "$photoTitle" berhasil ditambahkan',
                              ),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
          ),
    );
  }

  // Scan document from camera
  void _scanFromCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentScannerScreen(
          useGallery: false,
          onDocumentsScanned: (List<String> scannedImagePaths) {
            _handleScannedDocuments(scannedImagePaths, 'Dokumen Scan dari Kamera');
          },
        ),
      ),
    );
  }

  // Scan document from gallery
  void _scanFromGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentScannerScreen(
          useGallery: true,
          onDocumentsScanned: (List<String> scannedImagePaths) {
            _handleScannedDocuments(scannedImagePaths, 'Dokumen Scan dari Galeri');
          },
        ),
      ),
    );
  }

  // Handle scanned documents - show validation dialog for multiple images
  void _handleScannedDocuments(List<String> imagePaths, String defaultTitle) {
    if (imagePaths.isEmpty) return;
    
    if (imagePaths.length == 1) {
      // Single document - process directly
      _processSelectedImage(imagePaths.first, defaultTitle);
    } else {
      // Multiple documents - show validation dialog
      _showScannedDocumentsValidationDialog(imagePaths, defaultTitle);
    }
  }

  // Show validation dialog for multiple scanned documents
  void _showScannedDocumentsValidationDialog(List<String> imagePaths, String defaultTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Pilih Cara Menyimpan',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${imagePaths.length} dokumen berhasil di-scan.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              // Multi-Photo option
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _processMultipleScannedImages(imagePaths, defaultTitle);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF2563EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.collections, color: Color(0xFF2563EB)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halaman Multi-Dokumen',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            Text(
                              'Semua dokumen dalam satu halaman yang bisa di-swipe',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Individual photos option
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _processIndividualScannedImages(imagePaths, defaultTitle);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF10B981)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.photo, color: Color(0xFF10B981)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dokumen Terpisah',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            Text(
                              'Setiap dokumen sebagai item terpisah di galeri',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  // Process multiple scanned images as photo page
  void _processMultipleScannedImages(List<String> imagePaths, String defaultTitle) {
    // Convert paths to XFile-like objects for existing method
    List<XFile> xFiles = imagePaths.map((path) => XFile(path)).toList();
    _processMultipleImages(xFiles);
  }

  // Process individual scanned images
  void _processIndividualScannedImages(List<String> imagePaths, String defaultTitle) {
    // Convert paths to XFile-like objects for existing method
    List<XFile> xFiles = imagePaths.map((path) => XFile(path)).toList();
    _processIndividualImages(xFiles);
  }

  void _showFilterDialog() {
    final usedTags = _dataService.getUsedTags();
    if (usedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada tag yang tersedia untuk filter'),
        ),
      );
      return;
    }

    List<String> tempSelectedTags = List.from(_selectedTags);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Filter Berdasarkan Tag',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children:
                              usedTags.map((tag) {
                                final isSelected = tempSelectedTags.contains(
                                  tag,
                                );
                                return FilterChip(
                                  label: Text(tag),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setDialogState(() {
                                      if (selected) {
                                        tempSelectedTags.add(tag);
                                      } else {
                                        tempSelectedTags.remove(tag);
                                      }
                                    });
                                  },
                                  selectedColor: const Color(
                                    0xFF2563EB,
                                  ).withOpacity(0.2),
                                  checkmarkColor: const Color(0xFF2563EB),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          tempSelectedTags.clear();
                        });
                      },
                      child: const Text('Reset'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTags = tempSelectedTags;
                        });
                        _updateFilteredPhotos();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Terapkan'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _deletePhoto(PhotoModel photo) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Hapus Foto'),
            content: Text(
              'Apakah Anda yakin ingin menghapus "${photo.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  _dataService.deletePhoto(photo.id);
                  _updateFilteredPhotos();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Foto "${photo.title}" berhasil dihapus'),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
  }

  void _showMultiPhotoValidationDialog(List<XFile> images) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Pilih Cara Menambahkan Foto',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda memilih ${images.length} foto. Bagaimana Anda ingin menambahkannya?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.collections, size: 16, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Text(
                        'Multi-Photo Page',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Semua foto dalam satu halaman yang bisa di-swipe',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.photo, size: 16, color: Color(0xFF059669)),
                      SizedBox(width: 8),
                      Text(
                        'Foto Terpisah',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Setiap foto sebagai item terpisah di galeri',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processMultipleImages(images);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
            ),
            child: const Text('Multi-Photo'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processIndividualImages(images);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Foto Terpisah'),
          ),
        ],
      ),
    );
  }

  Future<void> _processIndividualImages(List<XFile> images) async {
    try {
      // Save all images first without showing dialogs
      List<String> savedPaths = [];
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Save all images to app directory
      for (XFile image in images) {
        final savedPath = await _dataService.savePhotoFile(image.path);
        savedPaths.add(savedPath);
      }

      Navigator.pop(context); // Close loading dialog
      
      // Show batch dialog for all photos
      _showBatchPhotoDialog(savedPaths);
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan foto: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showBatchPhotoDialog(List<String> imagePaths) {
    final TextEditingController prefixController = TextEditingController(
      text: 'Foto dari Galeri',
    );
    final TextEditingController descriptionController = TextEditingController();
    List<String> selectedTags = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Tambah ${imagePaths.length} Foto',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: prefixController,
                  decoration: const InputDecoration(
                    labelText: 'Prefix Judul (akan ditambah nomor)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tag (opsional):',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _dataService.availableTags.map((tag) {
                    final isSelected = selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedTags.add(tag);
                          } else {
                            selectedTags.remove(tag);
                          }
                        });
                      },
                      selectedColor: const Color(0xFF2563EB).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF2563EB),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tag baru (pisahkan dengan koma)',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    final newTags = value
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toList();
                    setDialogState(() {
                      for (String tag in newTags) {
                        if (!selectedTags.contains(tag)) {
                          selectedTags.add(tag);
                        }
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefix = prefixController.text.trim();
                final description = descriptionController.text.trim();

                if (prefix.isNotEmpty) {
                  // Show loading for batch creation
                  Navigator.pop(context); // Close dialog first
                  
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  try {
                    // Add all photos with sequential titles
                    for (int i = 0; i < imagePaths.length; i++) {
                      _dataService.addPhoto(
                        title: '$prefix ${i + 1}',
                        imagePath: imagePaths[i],
                        tags: selectedTags,
                        description: description,
                      );
                    }

                    _updateFilteredPhotos();
                    Navigator.pop(context); // Close loading dialog

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${imagePaths.length} foto berhasil ditambahkan'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context); // Close loading dialog
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menambahkan foto: ${e.toString()}'),
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan Semua'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processMultipleImages(List<XFile> images) async {
    try {
      // Save all images to app directory
      List<String> savedPaths = [];
      for (XFile image in images) {
        final savedPath = await _dataService.savePhotoFile(image.path);
        savedPaths.add(savedPath);
      }

      _showPhotoPageCreationDialog(savedPaths);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan foto: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showPhotoPageCreationDialog(List<String> imagePaths) {
    final TextEditingController titleController = TextEditingController(
      text: 'Halaman Foto ${DateTime.now().day}/${DateTime.now().month}',
    );
    final TextEditingController descriptionController = TextEditingController();
    List<String> selectedTags = [];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Buat Halaman Foto',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${imagePaths.length} foto dipilih',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Judul Halaman',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi (Opsional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Pilih Tag (Opsional):',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children:
                              _dataService.availableTags.map((tag) {
                                final isSelected = selectedTags.contains(tag);
                                return FilterChip(
                                  label: Text(tag),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setDialogState(() {
                                      if (selected) {
                                        selectedTags.add(tag);
                                      } else {
                                        selectedTags.remove(tag);
                                      }
                                    });
                                  },
                                  selectedColor: const Color(
                                    0xFF2563EB,
                                  ).withOpacity(0.2),
                                  checkmarkColor: const Color(0xFF2563EB),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Delete saved images if user cancels
                        for (String path in imagePaths) {
                          File(path).delete().catchError((_) {});
                        }
                      },
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final pageTitle = titleController.text.trim();
                        final pageDescription =
                            descriptionController.text.trim();

                        if (pageTitle.isNotEmpty) {
                          _dataService.addPhotoPage(
                            title: pageTitle,
                            imagePaths: imagePaths,
                            tags: selectedTags,
                            description: pageDescription,
                          );
                          _updateFilteredPhotos();
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Halaman foto "$pageTitle" berhasil dibuat dengan ${imagePaths.length} foto',
                              ),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Buat Halaman'),
                    ),
                  ],
                ),
          ),
    );
  }
}
