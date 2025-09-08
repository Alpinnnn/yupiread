import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/data_service.dart';
import '../models/photo_model.dart';
import '../l10n/app_localizations.dart';
import 'photo_view_screen.dart';
import 'photo_page_view_screen.dart';
import 'document_scanner_screen.dart';

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
  final ImagePicker _picker = ImagePicker();
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

  Future<void> _addPhotoToFolder() async {
    final localizations = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizations.addPhotoToFolder,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAddPhotoOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _buildAddPhotoOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop(); // Close bottom sheet
    
    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        await _processImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processImage(String imagePath) async {
    final localizations = AppLocalizations.of(context);
    
    // Show dialog to get photo title
    String? title = await _showTitleDialog();
    if (title == null || title.isEmpty) return;

    try {
      _dataService.addPhotoToFolder(
        title: title,
        imagePath: imagePath,
        folderName: widget.folderName,
        activityTitle: localizations.photoAddedToFolder(widget.folderName),
        activityDescription: title,
      );

      _loadFolderPhotos(); // Refresh the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.photoAddedToFolder(widget.folderName)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding photo: $e')),
        );
      }
    }
  }

  Future<String?> _showTitleDialog() async {
    final localizations = AppLocalizations.of(context);
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.addPhoto),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Title',
              hintText: 'Enter photo title',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: Text(localizations.add),
            ),
          ],
        );
      },
    );
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

    return Center(
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addPhotoToFolder,
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(localizations.addPhotoToFolder),
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
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: _folderPhotoPages.length + _folderPhotos.length + 1, // +1 for add button
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddPhotoCard();
          }
          
          final adjustedIndex = index - 1;
          if (adjustedIndex < _folderPhotoPages.length) {
            return _buildPhotoPageCard(_folderPhotoPages[adjustedIndex]);
          } else {
            final photoIndex = adjustedIndex - _folderPhotoPages.length;
            return _buildPhotoCard(_folderPhotos[photoIndex]);
          }
        },
      ),
    );
  }

  Widget _buildPhotoCard(PhotoModel photo) {
    return GestureDetector(
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
    );
  }

  Widget _buildAddPhotoCard() {
    final localizations = AppLocalizations.of(context);
    return GestureDetector(
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
    return GestureDetector(
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
    );
  }
}
