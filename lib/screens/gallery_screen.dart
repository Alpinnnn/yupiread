import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import '../services/data_service.dart';
import '../models/photo_model.dart';
import '../screens/photo_view_screen.dart';
import '../screens/photo_page_view_screen.dart';
import '../screens/folder_view_screen.dart';
import '../screens/gallery_settings_screen.dart';
import '../l10n/app_localizations.dart';
import 'text_scanner_screen.dart';
import 'document_scanner_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final DataService _dataService = DataService();
  List<PhotoModel> _filteredPhotos = [];
  List<PhotoPageModel> _filteredPhotoPages = [];
  List<String> _selectedTags = [];
  bool _folderViewMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    await _loadFolderViewState();
    _updateFilteredPhotos();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFolderViewState() async {
    final savedFolderViewMode = await _dataService.loadFolderViewMode();
    if (mounted) {
      setState(() {
        _folderViewMode = savedFolderViewMode;
      });
    }
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
      // Create mutable copies to allow reordering
      _filteredPhotos = List<PhotoModel>.from(
        _dataService.getFilteredPhotos(_selectedTags),
      );
      _filteredPhotoPages = List<PhotoPageModel>.from(
        _dataService.getFilteredPhotoPages(_selectedTags),
      );
    });
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      // Adjust indices to account for add button at index 0
      final adjustedOldIndex = oldIndex - 1;
      final adjustedNewIndex = newIndex - 1;

      // Create working copies of the lists
      final workingPhotoPages = List<PhotoPageModel>.from(_filteredPhotoPages);
      final workingPhotos = List<PhotoModel>.from(_filteredPhotos);

      if (adjustedOldIndex < workingPhotoPages.length &&
          adjustedNewIndex < workingPhotoPages.length) {
        // Reordering within photo pages
        final item = workingPhotoPages.removeAt(adjustedOldIndex);
        workingPhotoPages.insert(adjustedNewIndex, item);
        _filteredPhotoPages = workingPhotoPages;
        _dataService.reorderPhotoPages(workingPhotoPages);
      } else if (adjustedOldIndex >= workingPhotoPages.length &&
          adjustedNewIndex >= workingPhotoPages.length) {
        // Reordering within photos
        final photoOldIndex = adjustedOldIndex - workingPhotoPages.length;
        final photoNewIndex = adjustedNewIndex - workingPhotoPages.length;
        final item = workingPhotos.removeAt(photoOldIndex);
        workingPhotos.insert(photoNewIndex, item);
        _filteredPhotos = workingPhotos;
        _dataService.reorderPhotos(workingPhotos);
      } else {
        // Mixed reordering - maintain original types, just reorder positions
        // Create a combined list to determine new order
        List<dynamic> combinedItems = [];
        combinedItems.addAll(workingPhotoPages);
        combinedItems.addAll(workingPhotos);
        
        // Move item to new position
        final item = combinedItems.removeAt(adjustedOldIndex);
        combinedItems.insert(adjustedNewIndex, item);
        
        // Separate back into photo pages and photos
        workingPhotoPages.clear();
        workingPhotos.clear();
        
        for (final item in combinedItems) {
          if (item is PhotoPageModel) {
            workingPhotoPages.add(item);
          } else if (item is PhotoModel) {
            workingPhotos.add(item);
          }
        }
        
        // Update both lists and save
        _filteredPhotoPages = workingPhotoPages;
        _filteredPhotos = workingPhotos;
        _dataService.reorderMixedItems(workingPhotoPages, workingPhotos);
      }
    });
  }

  void _toggleFolderView() {
    if (mounted) {
      setState(() {
        _folderViewMode = !_folderViewMode;
      });

      // Save the folder view state asynchronously
      _dataService.saveFolderViewMode(_folderViewMode);
    }
  }

  Widget _buildPhotoGridView() {
    // Create a combined list with keys for reordering
    List<Widget> allItems = [];

    // Add photo card (non-reorderable) with key
    allItems.add(
      Container(
        key: const ValueKey('add_photo_card'),
        child: _buildAddPhotoCard(context),
      ),
    );

    // Add photo pages with keys
    for (int i = 0; i < _filteredPhotoPages.length; i++) {
      allItems.add(
        Container(
          key: ValueKey('photopage_${_filteredPhotoPages[i].id}'),
          child: _buildPhotoPageCard(context, _filteredPhotoPages[i]),
        ),
      );
    }

    // Add photos with keys
    for (int i = 0; i < _filteredPhotos.length; i++) {
      allItems.add(
        Container(
          key: ValueKey('photo_${_filteredPhotos[i].id}'),
          child: _buildPhotoCard(context, _filteredPhotos[i]),
        ),
      );
    }

    return ReorderableGridView.count(
      crossAxisCount: _getCrossAxisCount(context),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: allItems,
      onReorder: (oldIndex, newIndex) {
        if (oldIndex == 0 || newIndex == 0) return; // Don't reorder add button
        _handleReorder(oldIndex, newIndex);
      },
    );
  }

  Widget _buildFolderView() {
    final folders = _dataService.getPhotoFolders();
    final folderNames = folders.keys.toList();
    folderNames.sort();
    
    final untaggedPhotos = _dataService.getUntaggedPhotos();
    final totalItems = folderNames.length + untaggedPhotos.length + 1; // +1 for add photo card

    if (totalItems == 1) { // Only add photo card
      return _buildEmptyFolderView();
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // First item is always the add photo card
        if (index == 0) {
          return _buildAddPhotoCard(context);
        }
        
        final adjustedIndex = index - 1;
        
        // Show folder cards
        if (adjustedIndex < folderNames.length) {
          final folderName = folderNames[adjustedIndex];
          final folderPhotos = folders[folderName]!;
          return _buildFolderCard(folderName, folderPhotos);
        } 
        // Then show individual untagged photos
        else {
          final photoIndex = adjustedIndex - folderNames.length;
          final photo = untaggedPhotos[photoIndex];
          return _buildPhotoCard(context, photo);
        }
      },
    );
  }

  Widget _buildEmptyFolderView() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: 1, // Only show add photo card
      itemBuilder: (context, index) {
        return _buildAddPhotoCard(context);
      },
    );
  }

  Widget _buildFolderCard(String folderName, List<PhotoModel> photos) {
    final localizations = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FolderViewScreen(folderName: folderName),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).cardTheme.shadowColor ??
                  Colors.black.withOpacity(0.04),
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
                      _buildFolderThumbnail(photos),
                      // Folder icon overlay
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.folder,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${photos.length}',
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
                    folderName,
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
                    localizations.folderPhotosCount(photos.length),
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

  Widget _buildFolderThumbnail(List<PhotoModel> photos) {
    if (photos.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200],
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 32, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Empty Folder',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (photos.length == 1) {
      return Image.file(
        File(photos.first.imagePath),
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
                Icon(Icons.broken_image, size: 32, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Failed to load',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        },
      );
    }

    // Grid of 4 photos
    final displayPhotos = photos.take(4).toList();
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        if (index < displayPhotos.length) {
          return Image.file(
            File(displayPhotos[index].imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 16,
                ),
              );
            },
          );
        } else {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.photo, color: Colors.grey, size: 16),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                        l10n.myGallery,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_filteredPhotos.length + _filteredPhotoPages.length} ${l10n.photos}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Edit button
                      _buildActionButton(
                        icon: Icons.edit,
                        onPressed: _openEditMode,
                        tooltip: 'Edit Gallery',
                      ),
                      const SizedBox(width: 8),
                      // Folder view toggle button
                      _buildActionButton(
                        icon: _folderViewMode ? Icons.grid_view : Icons.folder,
                        onPressed: _toggleFolderView,
                        tooltip:
                            _folderViewMode
                                ? l10n.viewAsGrid
                                : l10n.viewAsFolders,
                      ),
                      const SizedBox(width: 8),
                      // Filter button
                      _buildActionButton(
                        icon:
                            _selectedTags.isEmpty
                                ? Icons.filter_list
                                : Icons.filter_list,
                        onPressed: _showFilterDialog,
                        badge:
                            _selectedTags.isNotEmpty
                                ? _selectedTags.length
                                : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child:
                    _folderViewMode
                        ? _buildFolderView()
                        : _buildPhotoGridView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPhotoCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              color:
                  Theme.of(context).cardTheme.shadowColor ??
                  Colors.black.withOpacity(0.04),
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
              l10n.addPhoto,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.newNote,
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
              color:
                  Theme.of(context).cardTheme.shadowColor ??
                  Colors.black.withOpacity(0.04),
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.broken_image,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context).failedToLoad,
                                  style: const TextStyle(
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
              color:
                  Theme.of(context).cardTheme.shadowColor ??
                  Colors.black.withOpacity(0.04),
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.broken_image,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context).failedToLoad,
                                  style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
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
                  l10n.addPhotoNote,
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
                        icon: Icons.document_scanner,
                        title: l10n.scanDocument,
                        onTap: () {
                          Navigator.pop(context);
                          _scanFromGallery();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildBottomSheetOption(
                        icon: Icons.text_fields,
                        title: l10n.scanText,
                        onTap: () {
                          Navigator.pop(context);
                          _scanTextFromPhoto();
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

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    int? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).cardTheme.shadowColor ??
                Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Stack(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            if (badge != null && badge > 0)
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
                    '$badge',
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
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Future<void> _safeDeleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Silently handle file deletion errors
    }
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
            content: Text(
              AppLocalizations.of(context).failedToSavePhotoError(e.toString()),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showTagSelectionDialog(String title, String imagePath) {
    final TextEditingController titleController = TextEditingController();
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
                  title: Text(AppLocalizations.of(context).addPhotoNote),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context).photoTitle,
                            hintText: title,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(
                                  context,
                                ).descriptionOptional,
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).selectTagsOptional,
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
                                  label: Text(
                                    tag,
                                    style: TextStyle(
                                      color:
                                          isSelected &&
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                              ? Colors.white
                                              : null,
                                    ),
                                  ),
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
                                  selectedColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(
                                            0xFF3B82F6,
                                          ).withOpacity(0.3)
                                          : const Color(
                                            0xFF2563EB,
                                          ).withOpacity(0.2),
                                  checkmarkColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF60A5FA)
                                          : const Color(0xFF2563EB),
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
                        _safeDeleteFile(imagePath);
                      },
                      child: Text(AppLocalizations.of(context).cancel),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final photoTitle = titleController.text.trim();
                        final photoDescription =
                            descriptionController.text.trim();

                        final finalTitle =
                            photoTitle.isNotEmpty ? photoTitle : title;
                        final l10n = AppLocalizations.of(context);
                        _dataService.addPhoto(
                          title: finalTitle,
                          imagePath: imagePath,
                          tags: selectedTags,
                          description: photoDescription,
                          activityTitle: l10n.photoAdded(finalTitle),
                          activityDescription: l10n.photoAddedDesc,
                        );
                        _updateFilteredPhotos();
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              ).photoAddedSuccessfully(finalTitle),
                            ),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(AppLocalizations.of(context).save),
                    ),
                  ],
                ),
          ),
    );
  }

  // Scan document from gallery
  void _scanFromGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DocumentScannerScreen(
              useGallery: true,
              onDocumentsScanned: (List<String> scannedImagePaths) {
                _handleScannedDocuments(
                  scannedImagePaths,
                  AppLocalizations.of(context).scannedFromGallery,
                );
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

  // Scan text from photo
  void _scanTextFromPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Navigate to text scanner screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => TextScannerScreen(
                  imageFile: imageFile,
                  saveImage: false, // Don't save the image, just scan text
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).failedToSelectPhotoError(e.toString()),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  // Show validation dialog for multiple scanned documents
  void _showScannedDocumentsValidationDialog(
    List<String> imagePaths,
    String defaultTitle,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(AppLocalizations.of(context).selectSaveMethod),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(
                  context,
                ).documentsScannedCount(imagePaths.length),
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
                  child: Row(
                    children: [
                      Icon(Icons.collections, color: Color(0xFF2563EB)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).multiDocumentPage,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            Text(
                              AppLocalizations.of(
                                context,
                              ).multiDocumentPageDesc,
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
                  child: Row(
                    children: [
                      Icon(Icons.photo, color: Color(0xFF10B981)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).separateDocuments,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            Text(
                              AppLocalizations.of(
                                context,
                              ).separateDocumentsDesc,
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
              child: Text(AppLocalizations.of(context).cancel),
            ),
          ],
        );
      },
    );
  }

  // Process multiple scanned images as photo page
  void _processMultipleScannedImages(
    List<String> imagePaths,
    String defaultTitle,
  ) {
    // Convert paths to XFile-like objects for existing method
    List<XFile> xFiles = imagePaths.map((path) => XFile(path)).toList();
    _processMultipleImages(xFiles);
  }

  // Process individual scanned images
  void _processIndividualScannedImages(
    List<String> imagePaths,
    String defaultTitle,
  ) {
    // Convert paths to XFile-like objects for existing method
    List<XFile> xFiles = imagePaths.map((path) => XFile(path)).toList();
    _processIndividualImages(xFiles);
  }

  void _showFilterDialog() {
    final usedTags = _dataService.getUsedTags();
    if (usedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).noTagsAvailableForFilter),
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
                  title: Text(AppLocalizations.of(context).filterByTags),
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
                                  label: Text(
                                    tag,
                                    style: TextStyle(
                                      color:
                                          isSelected &&
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                              ? Colors.white
                                              : null,
                                    ),
                                  ),
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
                                  selectedColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(
                                            0xFF3B82F6,
                                          ).withOpacity(0.3)
                                          : const Color(
                                            0xFF2563EB,
                                          ).withOpacity(0.2),
                                  checkmarkColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF60A5FA)
                                          : const Color(0xFF2563EB),
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
                      child: Text(AppLocalizations.of(context).reset),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context).cancel),
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
                      child: Text(AppLocalizations.of(context).apply),
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
            title: Text(AppLocalizations.of(context).deletePhotoTitle),
            content: Text(
              AppLocalizations.of(context).deletePhotoMessage(photo.title),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  final l10n = AppLocalizations.of(context);
                  _dataService.deletePhoto(
                    photo.id,
                    activityTitle: l10n.photoDeleted(photo.title),
                    activityDescription: l10n.photoDeletedDesc,
                  );
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
                child: Text(AppLocalizations.of(context).delete),
              ),
            ],
          ),
    );
  }

  void _showMultiPhotoValidationDialog(List<XFile> images) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              AppLocalizations.of(context).selectAddMethod,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).youSelected(images.length),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.collections,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).multiPhotoPageTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context).multiPhotoPageDesc,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.photo,
                            size: 16,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).separatePhotos,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context).separatePhotosDesc,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
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
                child: Text(AppLocalizations.of(context).multiPhoto),
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
                child: Text(AppLocalizations.of(context).separatePhotos),
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
        builder: (context) => const Center(child: CircularProgressIndicator()),
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
            content: Text(
              AppLocalizations.of(context).failedToSavePhotoError(e.toString()),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showBatchPhotoDialog(List<String> imagePaths) {
    final TextEditingController prefixController = TextEditingController(
      text: AppLocalizations.of(context).photoFromGallery,
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
                          children:
                              _dataService.availableTags.map((tag) {
                                final isSelected = selectedTags.contains(tag);
                                return FilterChip(
                                  label: Text(
                                    tag,
                                    style: TextStyle(
                                      color:
                                          isSelected &&
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                              ? Colors.white
                                              : null,
                                    ),
                                  ),
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
                                  selectedColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(
                                            0xFF3B82F6,
                                          ).withOpacity(0.3)
                                          : const Color(
                                            0xFF2563EB,
                                          ).withOpacity(0.2),
                                  checkmarkColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF60A5FA)
                                          : const Color(0xFF2563EB),
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
                            final newTags =
                                value
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
                      child: Text(AppLocalizations.of(context).cancel),
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
                            builder:
                                (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          );

                          try {
                            // Add all photos with sequential titles
                            final l10n = AppLocalizations.of(context);
                            for (int i = 0; i < imagePaths.length; i++) {
                              final photoTitle = '$prefix ${i + 1}';
                              _dataService.addPhoto(
                                title: photoTitle,
                                imagePath: imagePaths[i],
                                tags: selectedTags,
                                description: description,
                                activityTitle: l10n.photoAdded(photoTitle),
                                activityDescription: l10n.photoAddedDesc,
                              );
                            }

                            _updateFilteredPhotos();
                            Navigator.pop(context); // Close loading dialog

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${imagePaths.length} foto berhasil ditambahkan',
                                ),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          } catch (e) {
                            Navigator.pop(context); // Close loading dialog

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Gagal menambahkan foto: ${e.toString()}',
                                ),
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
            content: Text(
              AppLocalizations.of(context).failedToSavePhotoError(e.toString()),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showPhotoPageCreationDialog(List<String> imagePaths) {
    final TextEditingController titleController = TextEditingController(
      text:
          '${AppLocalizations.of(context).photoPage} ${DateTime.now().day}/${DateTime.now().month}',
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
                  title: Text(
                    AppLocalizations.of(context).createPhotoPageTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          ).photosSelected(imagePaths.length),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context).pageTitle,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(
                                  context,
                                ).descriptionOptional,
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).selectTagsOptional,
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
                                  label: Text(
                                    tag,
                                    style: TextStyle(
                                      color:
                                          isSelected &&
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                              ? Colors.white
                                              : null,
                                    ),
                                  ),
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
                                  selectedColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(
                                            0xFF3B82F6,
                                          ).withOpacity(0.3)
                                          : const Color(
                                            0xFF2563EB,
                                          ).withOpacity(0.2),
                                  checkmarkColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF60A5FA)
                                          : const Color(0xFF2563EB),
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
                          _safeDeleteFile(path);
                        }
                      },
                      child: Text(AppLocalizations.of(context).cancel),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final pageTitle = titleController.text.trim();
                        final pageDescription =
                            descriptionController.text.trim();

                        if (pageTitle.isNotEmpty) {
                          final l10n = AppLocalizations.of(context);
                          _dataService.addPhotoPage(
                            title: pageTitle,
                            imagePaths: imagePaths,
                            tags: selectedTags,
                            description: pageDescription,
                            activityTitle: l10n.photoPageAdded(pageTitle),
                            activityDescription: l10n.photoPageAddedDesc(
                              imagePaths.length,
                            ),
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

  void _openEditMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GallerySettingsScreen(),
      ),
    ).then((_) => _updateFilteredPhotos()); // Refresh when returning
  }
}
