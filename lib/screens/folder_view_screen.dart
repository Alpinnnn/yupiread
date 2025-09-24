import 'package:flutter/material.dart';
import 'dart:io';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../services/data_service.dart';
import '../models/photo_model.dart';
import '../l10n/app_localizations.dart';
import 'photo_view_screen.dart';
import 'photo_page_view_screen.dart';
import 'document_scanner_screen.dart';
import 'gallery_settings_screen.dart';

class FolderViewScreen extends StatefulWidget {
  final String folderName;

  const FolderViewScreen({
    super.key,
    required this.folderName,
  });

  @override
  State<FolderViewScreen> createState() => _FolderViewScreenState();
}

class _FolderViewScreenState extends State<FolderViewScreen> {
  final DataService _dataService = DataService();
  List<PhotoModel> _folderPhotos = [];
  List<PhotoPageModel> _folderPhotoPages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFolderPhotos();
  }

  void _loadFolderPhotos() {
    setState(() {
      _folderPhotos = _dataService.getPhotosForFolder(widget.folderName);
      _folderPhotoPages = _dataService.getPhotoPageForFolder(widget.folderName);
    });
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GallerySettingsScreen(),
                ),
              ).then((_) => _loadFolderPhotos());
            },
            tooltip: 'Edit Folder',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_folderPhotos.isEmpty && _folderPhotoPages.isEmpty)
              ? _buildEmptyState()
              : _buildPhotoGrid(),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Add photo card at the top
          SizedBox(
            height: 200,
            child: _buildAddPhotoCard(),
          ),
          const SizedBox(height: 32),
          // Empty state message
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.noPhotosInFolder,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add photos to this folder to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildPhotoGrid() {
    // Combine all items for reordering (excluding add photo card)
    final List<dynamic> allItems = [
      ..._folderPhotoPages,
      ..._folderPhotos,
    ];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ReorderableGridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: allItems.length + 1, // +1 for add button
        itemBuilder: (context, index) {
          if (index == 0) {
            // Add photo card - not draggable
            return _buildAddPhotoCard();
          }
          
          final adjustedIndex = index - 1;
          final item = allItems[adjustedIndex];
          
          if (item is PhotoPageModel) {
            return _buildPhotoPageCard(item);
          } else if (item is PhotoModel) {
            return _buildPhotoCard(item);
          }
          
          return Container(); // Fallback
        },
        onReorder: (oldIndex, newIndex) {
          // Prevent reordering if trying to move add photo card or move items to position 0
          if (oldIndex == 0 || newIndex == 0) {
            return;
          }
          
          setState(() {
            // Adjust indices to account for add photo card at position 0
            final adjustedOldIndex = oldIndex - 1;
            final adjustedNewIndex = newIndex - 1;
            
            // Reorder the combined list
            final item = allItems.removeAt(adjustedOldIndex);
            allItems.insert(adjustedNewIndex, item);
            
            // Update the original lists
            _updateOriginalLists(allItems);
          });
        },
      ),
    );
  }

  void _updateOriginalLists(List<dynamic> reorderedItems) {
    final List<PhotoPageModel> newPhotoPages = [];
    final List<PhotoModel> newPhotos = [];
    
    for (final item in reorderedItems) {
      if (item is PhotoPageModel) {
        newPhotoPages.add(item);
      } else if (item is PhotoModel) {
        newPhotos.add(item);
      }
    }
    
    _folderPhotoPages = newPhotoPages;
    _folderPhotos = newPhotos;
    
    // Update the data service with new order
    _dataService.reorderFolderItems(widget.folderName, newPhotoPages, newPhotos);
  }

  Widget _buildPhotoCard(PhotoModel photo) {
    return Container(
      key: ValueKey('photo_${photo.id}'), // Unique key for each photo
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhotoViewScreen(photoId: photo.id),
            ),
          ).then((_) => _loadFolderPhotos()); // Refresh when returning
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
      ),
    );
  }

  Widget _buildAddPhotoCard() {
    final localizations = AppLocalizations.of(context);
    return Container(
      key: const ValueKey('add_photo_card'), // Fixed key for add photo card
      child: GestureDetector(
        onTap: _scanFromGallery,
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
                localizations.addPhoto,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                localizations.newNote,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Scan document from gallery - directly opens document scanner
  void _scanFromGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentScannerScreen(
          useGallery: true,
          onDocumentsScanned: (List<String> scannedImagePaths) {
            _handleScannedDocuments(scannedImagePaths, AppLocalizations.of(context).scannedFromGallery);
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
            content: Text(AppLocalizations.of(context).failedToSavePhotoError(e.toString())),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showTagSelectionDialog(String title, String imagePath) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    List<String> selectedTags = [widget.folderName]; // Auto-add folder name as tag

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                    labelText: AppLocalizations.of(context).descriptionOptional,
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
                      selectedColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF3B82F6).withOpacity(0.3)
                          : const Color(0xFF2563EB).withOpacity(0.2),
                      checkmarkColor: Theme.of(context).brightness == Brightness.dark
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
                File(imagePath).delete().catchError((_) => File(''));
              },
              child: Text(AppLocalizations.of(context).cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final photoTitle = titleController.text.trim();
                final photoDescription = descriptionController.text.trim();

                final finalTitle = photoTitle.isNotEmpty ? photoTitle : title;
                final l10n = AppLocalizations.of(context);
                _dataService.addPhoto(
                  title: finalTitle,
                  imagePath: imagePath,
                  tags: selectedTags,
                  description: photoDescription,
                  activityTitle: l10n.photoAdded(finalTitle),
                  activityDescription: l10n.photoAddedDesc,
                );
                _loadFolderPhotos(); // Refresh folder photos
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context).photoAddedSuccessfully(finalTitle),
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

  void _showScannedDocumentsValidationDialog(List<String> imagePaths, String defaultTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Scanned Documents'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Found ${imagePaths.length} scanned documents'),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: ListView.builder(
                itemCount: imagePaths.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(imagePaths[index]),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text('Document ${index + 1}'),
                      subtitle: Text('Tap to edit'),
                      onTap: () {
                        Navigator.pop(context);
                        _processSelectedImage(imagePaths[index], '$defaultTitle ${index + 1}');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete all scanned images if user cancels
              for (String path in imagePaths) {
                File(path).delete().catchError((_) => File(''));
              }
            },
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Process all images with default titles
              for (int i = 0; i < imagePaths.length; i++) {
                _processSelectedImage(imagePaths[i], '$defaultTitle ${i + 1}');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).saveAll),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPageCard(PhotoPageModel photoPage) {
    return Container(
      key: ValueKey('photopage_${photoPage.id}'), // Unique key for each photo page
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhotoPageViewScreen(photoPageId: photoPage.id),
            ),
          ).then((_) => _loadFolderPhotos()); // Refresh when returning
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
      ),
    );
  }
}
