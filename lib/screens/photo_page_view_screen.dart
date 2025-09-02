import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:extended_image/extended_image.dart';
import '../models/photo_model.dart';
import '../services/data_service.dart';
import '../l10n/app_localizations.dart';
import 'text_scanner_screen.dart';
import 'package:path/path.dart' as path;

class PhotoPageViewScreen extends StatefulWidget {
  final String photoPageId;

  const PhotoPageViewScreen({super.key, required this.photoPageId});

  @override
  State<PhotoPageViewScreen> createState() => _PhotoPageViewScreenState();
}

class _PhotoPageViewScreenState extends State<PhotoPageViewScreen>
    with TickerProviderStateMixin {
  final DataService _dataService = DataService.instance;
  PhotoPageModel? photoPage;
  bool _showBottomBar = false;
  int _currentPhotoIndex = 0;
  late AnimationController _animationController;
  final PageController _pageController = PageController();
  final List<GlobalKey<ExtendedImageGestureState>> _gestureKeys = [];
  double _dragOffset = 0.0;
  double _bottomBarHeight = 300.0;
  DateTime? _lastSwipeTime;
  bool _isZoomed = false;
  final List<bool> _zoomStates = [];

  @override
  void initState() {
    super.initState();
    photoPage = _dataService.getPhotoPage(widget.photoPageId);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize gesture keys and zoom states for each photo
    _gestureKeys.clear();
    _zoomStates.clear();
    for (int i = 0; i < (photoPage?.imagePaths.length ?? 0); i++) {
      _gestureKeys.add(GlobalKey<ExtendedImageGestureState>());
      _zoomStates.add(false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleBottomBar() {
    setState(() {
      _showBottomBar = !_showBottomBar;
      // Reset drag offset when opening bottom bar
      if (_showBottomBar) {
        _dragOffset = 0.0;
      }
    });

    if (_showBottomBar) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _resetZoom() {
    if (_currentPhotoIndex < _gestureKeys.length) {
      _gestureKeys[_currentPhotoIndex].currentState?.reset();
      setState(() {
        _isZoomed = false;
        if (_currentPhotoIndex < _zoomStates.length) {
          _zoomStates[_currentPhotoIndex] = false;
        }
      });
    }
  }

  void _handleDoubleTap() {
    if (_currentPhotoIndex < _gestureKeys.length) {
      final ExtendedImageGestureState? gestureState =
          _gestureKeys[_currentPhotoIndex].currentState;
      if (gestureState != null) {
        final double scale = gestureState.gestureDetails?.totalScale ?? 1.0;

        if (scale > 1.01) {
          // Currently zoomed, zoom out to fit
          gestureState.handleDoubleTap(
            scale: 1.0,
            doubleTapPosition: gestureState.pointerDownPosition,
          );
        } else {
          // Currently not zoomed, zoom in to 2x
          gestureState.handleDoubleTap(
            scale: 2.0,
            doubleTapPosition: gestureState.pointerDownPosition,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (photoPage == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Halaman foto tidak ditemukan'),
        ),
        body: const Center(child: Text('Halaman foto tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              photoPage!.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Foto ${_currentPhotoIndex + 1} dari ${photoPage!.photoCount}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _toggleBottomBar,
          ),
        ],
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              if (_currentPhotoIndex < photoPage!.photoCount - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                return KeyEventResult.handled;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              if (_currentPhotoIndex > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                return KeyEventResult.handled;
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: () {
            if (_showBottomBar) {
              _toggleBottomBar();
            }
          },
          onDoubleTap: _handleDoubleTap,
          child: Stack(
            children: [
              // Main photo page view
              PageView.builder(
                controller: _pageController,
                physics:
                    _isZoomed
                        ? const NeverScrollableScrollPhysics()
                        : _CustomPageScrollPhysics(),
                onPageChanged: (index) {
                  final now = DateTime.now();
                  if (_lastSwipeTime != null &&
                      now.difference(_lastSwipeTime!).inMilliseconds < 300) {
                    return; // Ignore rapid swipes
                  }
                  _lastSwipeTime = now;

                  setState(() {
                    _currentPhotoIndex = index;
                    _isZoomed = false; // Reset zoom state when changing pages
                  });
                  _resetZoom();
                },
                itemCount: photoPage!.imagePaths.length,
                itemBuilder: (context, index) {
                  // Ensure we have enough gesture keys and zoom states
                  while (_gestureKeys.length <= index) {
                    _gestureKeys.add(GlobalKey<ExtendedImageGestureState>());
                    _zoomStates.add(false);
                  }

                  return ExtendedImage.file(
                    File(photoPage!.imagePaths[index]),
                    key: _gestureKeys[index],
                    fit: BoxFit.contain,
                    mode: ExtendedImageMode.gesture,
                    initGestureConfigHandler: (state) {
                      return GestureConfig(
                        minScale: 0.1,
                        maxScale: 5.0,
                        animationMinScale: 0.1,
                        animationMaxScale: 5.0,
                        speed: 1.0,
                        inertialSpeed: 100.0,
                        initialScale: 1.0,
                        inPageView:
                            false, // Changed to false to prevent gesture conflicts
                        initialAlignment: InitialAlignment.center,
                        cacheGesture:
                            false, // Disable gesture caching for better responsiveness
                        gestureDetailsIsChanged: (GestureDetails? details) {
                          // Track zoom state changes with improved detection
                          if (details != null && details.totalScale != null) {
                            final bool wasZoomed = _isZoomed;
                            final bool nowZoomed = details.totalScale! > 1.01;

                            if (wasZoomed != nowZoomed) {
                              setState(() {
                                _isZoomed = nowZoomed;
                                if (index < _zoomStates.length) {
                                  _zoomStates[index] = nowZoomed;
                                }
                              });
                            }
                          }
                        },
                      );
                    },
                    onDoubleTap: (ExtendedImageGestureState state) {
                      final Offset? pointerDownPosition =
                          state.pointerDownPosition;
                      final double? begin = state.gestureDetails?.totalScale;
                      double end;

                      if (begin == 1.0) {
                        end = 2.0;
                      } else {
                        end = 1.0;
                      }

                      state.handleDoubleTap(
                        scale: end,
                        doubleTapPosition: pointerDownPosition,
                      );
                    },
                    loadStateChanged: (ExtendedImageState state) {
                      switch (state.extendedImageLoadState) {
                        case LoadState.loading:
                          return Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        case LoadState.completed:
                          return null;
                        case LoadState.failed:
                          return Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.broken_image,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Gagal memuat foto',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                      }
                    },
                  );
                },
              ),

              // Thumbnail navigation strip
              if (photoPage!.photoCount > 1)
                Positioned(
                  bottom:
                      MediaQuery.of(context).orientation ==
                              Orientation.landscape
                          ? 20
                          : 40,
                  left: 0,
                  right: 0,
                  child: Container(
                    height:
                        MediaQuery.of(context).orientation ==
                                Orientation.landscape
                            ? 60
                            : 80,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ReorderableListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photoPage!.imagePaths.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = photoPage!.imagePaths.removeAt(oldIndex);
                          photoPage!.imagePaths.insert(newIndex, item);

                          // Update current index if needed
                          if (oldIndex == _currentPhotoIndex) {
                            _currentPhotoIndex = newIndex;
                            _pageController.animateToPage(
                              _currentPhotoIndex,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else if (oldIndex < _currentPhotoIndex &&
                              newIndex >= _currentPhotoIndex) {
                            _currentPhotoIndex -= 1;
                          } else if (oldIndex > _currentPhotoIndex &&
                              newIndex <= _currentPhotoIndex) {
                            _currentPhotoIndex += 1;
                          }

                          // Save the reordered photos to data service
                          _dataService.updatePhotoPage(
                            id: photoPage!.id,
                            imagePaths: photoPage!.imagePaths,
                          );
                        });
                      },
                      itemBuilder: (context, index) {
                        final isSelected = index == _currentPhotoIndex;
                        return Container(
                          key: ValueKey(photoPage!.imagePaths[index]),
                          width:
                              MediaQuery.of(context).orientation ==
                                      Orientation.landscape
                                  ? 50
                                  : 60,
                          height:
                              MediaQuery.of(context).orientation ==
                                      Orientation.landscape
                                  ? 50
                                  : 60,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.file(
                                      File(photoPage!.imagePaths[index]),
                                      width:
                                          MediaQuery.of(context).orientation ==
                                                  Orientation.landscape
                                              ? 50
                                              : 60,
                                      height:
                                          MediaQuery.of(context).orientation ==
                                                  Orientation.landscape
                                              ? 50
                                              : 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[800],
                                          child: const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                            size: 24,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                // Drag handle indicator
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.drag_handle,
                                      color: Colors.white,
                                      size: 12,
                                    ),
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

              // Bottom sheet with photo page details and actions
              if (_showBottomBar)
                Positioned(
                  bottom: _dragOffset,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onPanStart: (details) {
                      _dragOffset = 0.0;
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _dragOffset = (_dragOffset - details.delta.dy).clamp(
                          -_bottomBarHeight,
                          0.0,
                        );
                      });
                    },
                    onPanEnd: (details) {
                      if (_dragOffset < -_bottomBarHeight * 0.5) {
                        // Close if dragged more than 50%
                        _toggleBottomBar();
                      } else {
                        // Snap back to original position
                        setState(() {
                          _dragOffset = 0.0;
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Handle bar
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[600],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),

                              // Photo page details
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      photoPage!.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${photoPage!.photoCount} foto • ${photoPage!.timeAgo}',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),

                                    if (photoPage!.description.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        photoPage!.description,
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],

                                    if (photoPage!.tags.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children:
                                            photoPage!.tags.map((tag) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF2563EB,
                                                  ).withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF2563EB,
                                                    ).withOpacity(0.5),
                                                  ),
                                                ),
                                                child: Text(
                                                  tag,
                                                  style: const TextStyle(
                                                    color: Color(0xFF2563EB),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Action buttons
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[850],
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.edit,
                                      label: AppLocalizations.of(context).edit,
                                      onTap: _editPhotoPage,
                                    ),
                                    _buildActionButton(
                                      icon: Icons.add_photo_alternate,
                                      label: 'Tambah Foto',
                                      onTap: _addPhotoToPage,
                                    ),
                                    _buildActionButton(
                                      icon: Icons.share,
                                      label: AppLocalizations.of(context).share,
                                      onTap: _sharePhotoPage,
                                    ),
                                    _buildActionButton(
                                      icon: Icons.text_fields,
                                      label: 'Ekstrak Teks',
                                      onTap: _extractTextFromPage,
                                    ),
                                    _buildActionButton(
                                      icon: Icons.delete,
                                      label: AppLocalizations.of(context).delete,
                                      color: Colors.red,
                                      onTap: _deletePhotoPage,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _extractTextFromPage() async {
    try {
      // Navigate to text scanner with current photo from the page
      final currentImagePath = photoPage!.imagePaths[_currentPhotoIndex];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TextScannerScreen(
            imageFile: File(currentImagePath),
            saveImage: false,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka text scanner: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _editPhotoPage() {
    _showEditPhotoPageDialog();
  }

  void _showEditPhotoPageDialog() {
    final titleController = TextEditingController(text: photoPage!.title);
    final descriptionController = TextEditingController(
      text: photoPage!.description,
    );
    List<String> selectedTags = List.from(photoPage!.tags);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(AppLocalizations.of(context).editPhotoPage),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Judul',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tags',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<List<String>>(
                          future: Future.value(_dataService.availableTags),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }

                            final availableTags = snapshot.data!;
                            return Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children:
                                  availableTags.map((tag) {
                                    final isSelected = selectedTags.contains(
                                      tag,
                                    );
                                    return FilterChip(
                                      label: Text(tag),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedTags.add(tag);
                                          } else {
                                            selectedTags.remove(tag);
                                          }
                                        });
                                      },
                                      selectedColor: const Color(
                                        0xFF8B5CF6,
                                      ).withOpacity(0.2),
                                      checkmarkColor: const Color(0xFF8B5CF6),
                                    );
                                  }).toList(),
                            );
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
                        if (titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Judul tidak boleh kosong'),
                            ),
                          );
                          return;
                        }

                        try {
                          _dataService.updatePhotoPage(
                            id: photoPage!.id,
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            tags: selectedTags,
                          );

                          Navigator.pop(context);

                          // Refresh the photo page data
                          this.setState(() {
                            photoPage = _dataService.getPhotoPage(
                              widget.photoPageId,
                            );
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Halaman foto berhasil diperbarui'),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Gagal memperbarui halaman foto: $e',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _addPhotoToPage() {
    _showAddPhotoDialog();
  }

  void _showAddPhotoDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tambah Foto ke Halaman'),
            content: const Text('Pilih sumber foto yang ingin ditambahkan:'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickPhotosFromCamera();
                },
                child: Text(AppLocalizations.of(context).cameraOption),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickPhotosFromGallery();
                },
                child: Text(AppLocalizations.of(context).galleryOption),
              ),
            ],
          ),
    );
  }

  Future<void> _pickPhotosFromCamera() async {
    try {
      final XFile? photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        await _addPhotosToPage([photo.path]);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
    }
  }

  Future<void> _pickPhotosFromGallery() async {
    try {
      final List<XFile> photos = await ImagePicker().pickMultiImage(
        imageQuality: 80,
      );

      if (photos.isNotEmpty) {
        final photoPaths = photos.map((photo) => photo.path).toList();
        await _addPhotosToPage(photoPaths);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih foto: $e')));
    }
  }

  Future<void> _addPhotosToPage(List<String> newPhotoPaths) async {
    try {
      // Copy photos to app directory
      final List<String> savedPhotoPaths = [];

      for (String photoPath in newPhotoPaths) {
        final File sourceFile = File(photoPath);
        final String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${path.basename(photoPath)}';
        final appDir = await getApplicationDocumentsDirectory();
        final String savedPath = path.join(appDir.path, fileName);

        await sourceFile.copy(savedPath);
        savedPhotoPaths.add(savedPath);
      }

      // Update photo page with new photos
      final updatedImagePaths = [...photoPage!.imagePaths, ...savedPhotoPaths];

      _dataService.updatePhotoPage(
        id: photoPage!.id,
        imagePaths: updatedImagePaths,
      );

      // Refresh the photo page data
      setState(() {
        photoPage = _dataService.getPhotoPage(widget.photoPageId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${savedPhotoPaths.length} foto berhasil ditambahkan'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menambahkan foto: $e')));
    }
  }

  Future<void> _sharePhotoPage() async {
    try {
      final files = photoPage!.imagePaths.map((path) => XFile(path)).toList();

      String shareText = photoPage!.title;
      if (photoPage!.description.isNotEmpty) {
        shareText += '\n\n${photoPage!.description}';
      }
      shareText += '\n\n${photoPage!.photoCount} foto dibagikan dari Yupiread';

      await Share.shareXFiles(
        files,
        text: shareText,
        subject: photoPage!.title,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Halaman foto berhasil dibagikan'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan halaman foto: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _deletePhotoPage() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).deletePhotoPage),
            content: Text(
              AppLocalizations.of(context).deletePhotoPageConfirmation,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  _dataService.deletePhotoPage(photoPage!.id);
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to gallery
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(AppLocalizations.of(context).delete),
              ),
            ],
          ),
    );
  }
}

// Custom PageScrollPhysics with improved gesture handling
class _CustomPageScrollPhysics extends PageScrollPhysics {
  const _CustomPageScrollPhysics({ScrollPhysics? parent})
    : super(parent: parent);

  @override
  _CustomPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _CustomPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    // Only accept swipe gestures when not zoomed
    return super.shouldAcceptUserOffset(position);
  }

  @override
  double get minFlingVelocity => 200.0; // Higher threshold for more deliberate swipes

  @override
  double get dragStartDistanceMotionThreshold => 15.0; // Require more movement to start drag

  // Removed touchSlop override as it doesn't exist in PageScrollPhysics
}
