import 'package:flutter/material.dart';
import 'dart:io';
import '../models/photo_model.dart';
import '../services/data_service.dart';
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
              title: 'Edit',
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
              title: 'Delete',
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
              title: 'Edit',
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
              title: 'Delete',
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
    final totalItems = photoIds.length + photoPageIds.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Foto'),
        content: Text('Apakah Anda yakin ingin menghapus $totalItems item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedItems(photoIds, photoPageIds);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
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
        content: Text('${photoIds.length + photoPageIds.length} item berhasil dihapus'),
        backgroundColor: Colors.green,
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
                if (selectedCount > 0)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(
                      _selectedPhotoIds.toList(),
                      _selectedPhotoPageIds.toList(),
                    ),
                  ),
                if (selectedCount > 1)
                  IconButton(
                    icon: const Icon(Icons.merge, color: Color(0xFF2563EB)),
                    onPressed: _mergeSelectedItems,
                  ),
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
                '$totalItems foto tersimpan',
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
                              'Belum ada foto tersimpan',
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
    );
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
