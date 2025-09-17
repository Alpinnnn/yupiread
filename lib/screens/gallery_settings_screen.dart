import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/photo_model.dart';
import '../services/data_service.dart';
import '../l10n/app_localizations.dart';
import 'photo_view_screen.dart';
import 'photo_page_view_screen.dart';

class GallerySettingsScreen extends StatefulWidget {
  const GallerySettingsScreen({super.key});

  @override
  State<GallerySettingsScreen> createState() => _GallerySettingsScreenState();
}

class _GallerySettingsScreenState extends State<GallerySettingsScreen> {
  final DataService _dataService = DataService.instance;
  List<PhotoModel> _photos = [];
  List<PhotoPageModel> _photoPages = [];
  Set<String> _selectedPhotoIds = {};
  Set<String> _selectedPhotoPageIds = {};
  bool _isSelectMode = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  void _loadPhotos() {
    setState(() {
      _photos = _dataService.photos;
      _photoPages = _dataService.photoPages;
    });
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) {
        _selectedPhotoIds.clear();
        _selectedPhotoPageIds.clear();
      }
    });
  }

  void _togglePhotoSelection(String photoId) {
    setState(() {
      if (_selectedPhotoIds.contains(photoId)) {
        _selectedPhotoIds.remove(photoId);
      } else {
        _selectedPhotoIds.add(photoId);
      }
    });
  }

  void _togglePhotoPageSelection(String photoPageId) {
    setState(() {
      if (_selectedPhotoPageIds.contains(photoPageId)) {
        _selectedPhotoPageIds.remove(photoPageId);
      } else {
        _selectedPhotoPageIds.add(photoPageId);
      }
    });
  }

  void _showPhotoOptions(PhotoModel photo) {
    final localizations = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
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
              photo.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.edit,
              title: localizations.editTags,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoViewScreen(photoId: photo.id),
                  ),
                ).then((_) => _loadPhotos());
              },
            ),
            _buildOptionTile(
              icon: Icons.save_alt,
              title: 'Save to Gallery',
              subtitle: 'Simpan ke galeri perangkat',
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(context);
                _savePhotoToDeviceGallery(photo);
              },
            ),
            _buildOptionTile(
              icon: Icons.merge,
              title: 'Merge',
              subtitle: 'Gabungkan dengan foto lain',
              onTap: () {
                Navigator.pop(context);
                _toggleSelectMode();
                _selectedPhotoIds.add(photo.id);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete,
              title: localizations.delete,
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation([photo.id], []);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoPageOptions(PhotoPageModel photoPage) {
    final localizations = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
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
              photoPage.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.edit,
              title: localizations.editTags,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoPageViewScreen(photoPageId: photoPage.id),
                  ),
                ).then((_) => _loadPhotos());
              },
            ),
            _buildOptionTile(
              icon: Icons.save_alt,
              title: 'Save to Gallery',
              subtitle: 'Simpan semua foto ke galeri perangkat',
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(context);
                _savePhotoPageToDeviceGallery(photoPage);
              },
            ),
            _buildOptionTile(
              icon: Icons.merge,
              title: 'Merge',
              subtitle: 'Gabungkan dengan foto lain',
              onTap: () {
                Navigator.pop(context);
                _toggleSelectMode();
                _selectedPhotoPageIds.add(photoPage.id);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete,
              title: localizations.delete,
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation([], [photoPage.id]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation(List<String> photoIds, List<String> photoPageIds) {
    final localizations = AppLocalizations.of(context);
    final totalItems = photoIds.length + photoPageIds.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photos'),
        content: Text('Are you sure you want to delete $totalItems items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedItems(photoIds, photoPageIds);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );
  }

  void _deleteSelectedItems(List<String> photoIds, List<String> photoPageIds) {
    for (String photoId in photoIds) {
      _dataService.deletePhoto(photoId);
    }
    for (String photoPageId in photoPageIds) {
      _dataService.deletePhotoPage(photoPageId);
    }
    _loadPhotos();
    _toggleSelectMode();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${photoIds.length + photoPageIds.length} items deleted successfully'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
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

  void _mergeSelectedItems() async {
    if (_selectedPhotoIds.isEmpty && _selectedPhotoPageIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu foto untuk digabungkan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Collect all image paths from selected items
      List<String> originalImagePaths = [];
      List<String> allTags = [];

      // Add selected single photos
      for (String photoId in _selectedPhotoIds) {
        final photo = _photos.firstWhere((p) => p.id == photoId);
        originalImagePaths.add(photo.imagePath);
        allTags.addAll(photo.tags);
      }

      // Add selected photo pages
      for (String photoPageId in _selectedPhotoPageIds) {
        final photoPage = _photoPages.firstWhere((p) => p.id == photoPageId);
        originalImagePaths.addAll(photoPage.imagePaths);
        allTags.addAll(photoPage.tags);
      }

      // Remove duplicates from tags
      allTags = allTags.toSet().toList();

      if (originalImagePaths.length < 2) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Minimal 2 foto diperlukan untuk merge'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Copy image files to new locations to prevent corruption
      List<String> copiedImagePaths = [];
      for (String originalPath in originalImagePaths) {
        try {
          final copiedPath = await _dataService.savePhotoFile(originalPath);
          copiedImagePaths.add(copiedPath);
        } catch (e) {
          // If copying fails, use original path as fallback
          copiedImagePaths.add(originalPath);
        }
      }

      // Create new photo page with copied image paths
      _dataService.addPhotoPage(
        title: 'Merged Photos ${DateTime.now().day}/${DateTime.now().month}',
        imagePaths: copiedImagePaths,
        tags: allTags,
      );

      // Delete original items
      _deleteSelectedItems(_selectedPhotoIds.toList(), _selectedPhotoPageIds.toList());

      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto berhasil digabungkan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menggabungkan foto: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _photos.length + _photoPages.length;
    final selectedCount = _selectedPhotoIds.length + _selectedPhotoPageIds.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isSelectMode ? '$selectedCount dipilih' : 'Gallery Setting',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontSize: 18,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        actions: _isSelectMode
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleSelectMode,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _toggleSelectMode,
                ),
              ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$totalItems photos saved',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: totalItems == 0
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 64,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No photos saved yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getCrossAxisCount(context),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: totalItems,
                        itemBuilder: (context, index) {
                          if (index < _photos.length) {
                            return _buildPhotoCard(_photos[index]);
                          } else {
                            return _buildPhotoPageCard(_photoPages[index - _photos.length]);
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isSelectMode && selectedCount > 0
          ? FloatingActionButton(
              onPressed: _showSelectedItemsOptions,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.more_vert, color: Colors.white),
            )
          : null,
    );
  }

  void _showSelectedItemsOptions() {
    final selectedCount = _selectedPhotoIds.length + _selectedPhotoPageIds.length;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
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
              '$selectedCount item dipilih',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            const SizedBox(height: 20),
            if (selectedCount > 1)
              _buildOptionTile(
                icon: Icons.merge,
                title: 'Merge',
                subtitle: 'Gabungkan foto yang dipilih',
                color: const Color(0xFF2563EB),
                onTap: () {
                  Navigator.pop(context);
                  _mergeSelectedItems();
                },
              ),
            _buildOptionTile(
              icon: Icons.save_alt,
              title: 'Save to Gallery',
              subtitle: 'Simpan ke galeri perangkat',
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(context);
                _saveToDeviceGallery();
              },
            ),
            _buildOptionTile(
              icon: Icons.delete,
              title: 'Delete',
              subtitle: 'Hapus foto yang dipilih',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(
                  _selectedPhotoIds.toList(),
                  _selectedPhotoPageIds.toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
          'This app needs storage permission to save photos to your device gallery. Please grant storage permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<bool> _requestStoragePermission() async {
    // For Android 13+ (API 33+), we need to request READ_MEDIA_IMAGES
    // For Android 11-12 (API 30-32), we need MANAGE_EXTERNAL_STORAGE or READ_EXTERNAL_STORAGE
    // For Android 10 and below, we need WRITE_EXTERNAL_STORAGE
    
    // Check if photos permission is already granted (Android 13+)
    if (await Permission.photos.status.isGranted) {
      return true;
    }
    
    // Check if storage permission is already granted (Android 12 and below)
    if (await Permission.storage.status.isGranted) {
      return true;
    }
    
    // Request photos permission first (for Android 13+)
    final photosPermission = await Permission.photos.request();
    if (photosPermission.isGranted) {
      return true;
    }
    
    // If photos permission failed, try storage permission (for older Android)
    final storagePermission = await Permission.storage.request();
    if (storagePermission.isGranted) {
      return true;
    }
    
    // Check if any permission is permanently denied
    if (photosPermission.isPermanentlyDenied || storagePermission.isPermanentlyDenied) {
      _showPermissionDialog();
    } else if (photosPermission.isDenied || storagePermission.isDenied) {
      _showPermissionDialog();
    }
    
    return false;
  }

  void _saveToDeviceGallery() async {
    try {
      // Request storage permission with dialog
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return;
      }

      int savedCount = 0;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Saving photos to gallery...'),
            ],
          ),
        ),
      );

      // Save selected photos
      for (String photoId in _selectedPhotoIds) {
        final photo = _photos.firstWhere((p) => p.id == photoId);
        final success = await _saveImageToGallery(photo.imagePath, photo.title);
        if (success) savedCount++;
      }

      // Save photos from selected photo pages
      for (String photoPageId in _selectedPhotoPageIds) {
        final photoPage = _photoPages.firstWhere((p) => p.id == photoPageId);
        for (int i = 0; i < photoPage.imagePaths.length; i++) {
          final imagePath = photoPage.imagePaths[i];
          final fileName = '${photoPage.title}_${i + 1}';
          final success = await _saveImageToGallery(imagePath, fileName);
          if (success) savedCount++;
        }
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show result
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$savedCount photos saved to gallery'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }

      _toggleSelectMode(); // Exit selection mode
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save photos: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _savePhotoToDeviceGallery(PhotoModel photo) async {
    try {
      // Request storage permission with dialog
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Saving photo to gallery...'),
            ],
          ),
        ),
      );

      final success = await _saveImageToGallery(photo.imagePath, photo.title);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Photo saved to gallery successfully' 
              : 'Failed to save photo to gallery'),
            backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save photo: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _savePhotoPageToDeviceGallery(PhotoPageModel photoPage) async {
    try {
      // Request storage permission with dialog
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Saving ${photoPage.imagePaths.length} photos to gallery...'),
            ],
          ),
        ),
      );

      int savedCount = 0;
      for (int i = 0; i < photoPage.imagePaths.length; i++) {
        final imagePath = photoPage.imagePaths[i];
        final fileName = '${photoPage.title}_${i + 1}';
        final success = await _saveImageToGallery(imagePath, fileName);
        if (success) savedCount++;
      }
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$savedCount of ${photoPage.imagePaths.length} photos saved to gallery'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save photos: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<bool> _saveImageToGallery(String imagePath, String fileName) async {
    try {
      final sourceFile = File(imagePath);
      if (!await sourceFile.exists()) {
        return false;
      }

      // Get the public Pictures directory (DCIM/Pictures)
      Directory? picturesDir;
      
      // Try to get the public Pictures directory
      try {
        // For Android, use the public Pictures directory
        final externalDir = Directory('/storage/emulated/0/Pictures/Yupiread');
        picturesDir = externalDir;
      } catch (e) {
        // Fallback to DCIM directory
        try {
          final dcimDir = Directory('/storage/emulated/0/DCIM/Yupiread');
          picturesDir = dcimDir;
        } catch (e) {
          // Final fallback to external storage
          final directory = await getExternalStorageDirectory();
          if (directory == null) return false;
          picturesDir = Directory('${directory.path}/Pictures/Yupiread');
        }
      }

      // Create directory if it doesn't exist
      if (!await picturesDir.exists()) {
        await picturesDir.create(recursive: true);
      }

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imagePath.split('.').last;
      final targetPath = '${picturesDir.path}/${fileName}_$timestamp.$extension';

      // Copy file
      await sourceFile.copy(targetPath);
      
      // Trigger media scanner to make the image visible in gallery
      try {
        await _triggerMediaScan(targetPath);
      } catch (e) {
        debugPrint('Failed to trigger media scan: $e');
        // Continue anyway, file is still saved
      }
      
      return true;
    } catch (e) {
      debugPrint('Error saving image to gallery: $e');
      return false;
    }
  }

  Future<void> _triggerMediaScan(String filePath) async {
    // This would require a platform channel to trigger media scanner
    // For now, we'll use a simple approach by creating a .nomedia file and removing it
    try {
      final directory = Directory(filePath).parent;
      final nomediaFile = File('${directory.path}/.nomedia');
      
      // Create and immediately delete .nomedia to trigger media scan
      if (await nomediaFile.exists()) {
        await nomediaFile.delete();
      }
      await nomediaFile.create();
      await nomediaFile.delete();
    } catch (e) {
      debugPrint('Media scan trigger failed: $e');
    }
  }

  Widget _buildPhotoCard(PhotoModel photo) {
    final isSelected = _selectedPhotoIds.contains(photo.id);

    return GestureDetector(
      onTap: () {
        if (_isSelectMode) {
          _togglePhotoSelection(photo.id);
        } else {
          _showPhotoOptions(photo);
        }
      },
      onLongPress: () {
        if (!_isSelectMode) {
          _toggleSelectMode();
          _selectedPhotoIds.add(photo.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).cardTheme.shadowColor ?? Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
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
            if (_isSelectMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardTheme.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPageCard(PhotoPageModel photoPage) {
    final isSelected = _selectedPhotoPageIds.contains(photoPage.id);

    return GestureDetector(
      onTap: () {
        if (_isSelectMode) {
          _togglePhotoPageSelection(photoPage.id);
        } else {
          _showPhotoPageOptions(photoPage);
        }
      },
      onLongPress: () {
        if (!_isSelectMode) {
          _toggleSelectMode();
          _selectedPhotoPageIds.add(photoPage.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).cardTheme.shadowColor ?? Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
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
                          if (photoPage.imagePaths.isNotEmpty)
                            Image.file(
                              File(photoPage.imagePaths.first),
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
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.collections,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${photoPage.imagePaths.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
            if (_isSelectMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardTheme.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
