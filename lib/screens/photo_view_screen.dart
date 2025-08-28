import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:extended_image/extended_image.dart';
import '../models/photo_model.dart';
import '../services/data_service.dart';
import 'text_to_ebook_editor_screen.dart';

class PhotoViewScreen extends StatefulWidget {
  final String? photoId;
  final String? photoPageId;

  const PhotoViewScreen({super.key, this.photoId, this.photoPageId})
    : assert(
        photoId != null || photoPageId != null,
        'Either photoId or photoPageId must be provided',
      );

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen>
    with TickerProviderStateMixin {
  final DataService _dataService = DataService.instance;
  PhotoModel? photo;
  bool _showBottomBar = false;
  String? _imageResolution;
  String? _fileSize;
  late AnimationController _animationController;
  double _dragOffset = 0.0;
  double _bottomBarHeight = 300.0;
  final GlobalKey<ExtendedImageGestureState> _gestureKey = GlobalKey<ExtendedImageGestureState>();

  @override
  void initState() {
    super.initState();
    if (widget.photoId != null) {
      photo = _dataService.getPhoto(widget.photoId!);
    } else if (widget.photoPageId != null) {
      // Assuming you have a method to get photo from photo page id
      // photo = _dataService.getPhotoFromPageId(widget.photoPageId!);
    }
    _loadImageInfo();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );


  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadImageInfo() async {
    if (photo == null) return;

    try {
      final file = File(photo!.imagePath);

      // Get file size
      final fileStat = await file.stat();
      final sizeInBytes = fileStat.size;
      _fileSize = _formatFileSize(sizeInBytes);

      // Get image resolution
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      _imageResolution = '${image.width} x ${image.height}';

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _imageResolution = 'Tidak diketahui';
      _fileSize = 'Tidak diketahui';
      if (mounted) {
        setState(() {});
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _toggleBottomBar() {
    setState(() {
      if (_showBottomBar) {
        // Closing bottom bar
        _showBottomBar = false;
      } else {
        // Opening bottom bar - always reset drag offset
        _showBottomBar = true;
        _dragOffset = 0.0; // Reset to default position when opening
      }
    });
  }

  void _resetZoom() {
    _gestureKey.currentState?.reset();
  }

  void _handleDoubleTap() {
    final ExtendedImageGestureState? gestureState = _gestureKey.currentState;
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

  @override
  Widget build(BuildContext context) {
    if (photo == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Foto tidak ditemukan'),
        ),
        body: const Center(child: Text('Foto tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: _resetZoom,
            tooltip: 'Reset Zoom',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _toggleBottomBar,
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_showBottomBar) {
            _toggleBottomBar();
          }
        },
        onDoubleTap: _handleDoubleTap,
        child: Stack(
          children: [
            // Main photo view with extended_image
            Container(
              width: double.infinity,
              height: double.infinity,
              child: ExtendedImage.file(
                File(photo!.imagePath),
                key: _gestureKey,
                fit: BoxFit.contain,
                mode: ExtendedImageMode.gesture,
                enableMemoryCache: true,
                clearMemoryCacheIfFailed: false,
                initGestureConfigHandler: (state) {
                  return GestureConfig(
                    minScale: 0.1,
                    maxScale: 5.0,
                    animationMinScale: 0.1,
                    animationMaxScale: 5.0,
                    speed: 1.0,
                    inertialSpeed: 100.0,
                    initialScale: 1.0,
                    inPageView: false,
                    initialAlignment: InitialAlignment.center,
                    cacheGesture: false, // Disable gesture caching for better responsiveness
                    hitTestBehavior: HitTestBehavior.opaque, // Ensure all touch areas are responsive
                  );
                },
                onDoubleTap: (ExtendedImageGestureState state) {
                  final Offset? pointerDownPosition = state.pointerDownPosition;
                  final double? begin = state.gestureDetails?.totalScale;
                  double end;
                  
                  if (begin == null || begin <= 1.01) {
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
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.6,
                        padding: const EdgeInsets.all(20),
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
              ),
            ),

          // Bottom sheet with photo details and actions
          if (_showBottomBar)
            Positioned(
              bottom: _dragOffset,
              left: 0,
              right: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // Prevent tap from propagating to background
                },
                onPanStart: (details) {
                  _dragOffset = 0.0;
                },
                onPanUpdate: (details) {
                  setState(() {
                    _dragOffset = (_dragOffset - details.delta.dy).clamp(-_bottomBarHeight, 0.0);
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

                        // Photo details
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Photo title
                              Text(
                                photo!.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                photo!.timeAgo,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),

                              // Description
                              if (photo!.description.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  photo!.description,
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 14,
                                  ),
                                ),
                              ],

                              // Technical info
                              const SizedBox(height: 12),
                              _buildTechnicalInfo(),

                              // Tags
                              if (photo!.tags.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children:
                                      photo!.tags.map((tag) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF2563EB,
                                            ).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                icon: Icons.edit,
                                label: 'Edit',
                                onTap: () {
                                  _toggleBottomBar();
                                  _editPhoto();
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.share,
                                label: 'Bagikan',
                                onTap: () {
                                  _toggleBottomBar();
                                  _sharePhoto();
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.text_fields,
                                label: 'Ekstrak Teks',
                                onTap: () {
                                  _toggleBottomBar();
                                  _extractText();
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.delete,
                                label: 'Hapus',
                                color: Colors.red,
                                onTap: () {
                                  _toggleBottomBar();
                                  _deletePhoto();
                                },
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
    );
  }

  Widget _buildTechnicalInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Info Teknis',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Resolusi',
                  _imageResolution ?? 'Memuat...',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem('Ukuran', _fileSize ?? 'Memuat...'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editPhoto() {
    final TextEditingController titleController = TextEditingController(
      text: photo!.title,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: photo!.description,
    );
    List<String> selectedTags = List.from(photo!.tags);

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
                    'Edit Foto',
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
                          'Tag:',
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final newTitle = titleController.text.trim();
                        final newDescription =
                            descriptionController.text.trim();

                        if (newTitle.isNotEmpty) {
                          _dataService.updatePhoto(
                            id: photo!.id,
                            title: newTitle,
                            description: newDescription,
                            tags: selectedTags,
                          );

                          setState(() {
                            photo = _dataService.getPhoto(widget.photoId!);
                          });

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Foto berhasil diperbarui'),
                              backgroundColor: Color(0xFF10B981),
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

  Future<void> _sharePhoto() async {
    try {
      final file = File(photo!.imagePath);

      if (await file.exists()) {
        // Create share text
        String shareText = photo!.title;
        if (photo!.description.isNotEmpty) {
          shareText += '\n\n${photo!.description}';
        }
        shareText += '\n\nDibagikan dari YupiRead';

        // Create XFile for sharing
        final xFile = XFile(
          photo!.imagePath,
          name: '${photo!.title}.jpg',
          mimeType: 'image/jpeg',
        );

        await Share.shareXFiles(
          [xFile],
          text: shareText,
          subject: photo!.title,
        );

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto berhasil dibagikan'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File foto tidak ditemukan'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Detailed error handling
        String errorMessage = 'Gagal membagikan foto';
        if (e.toString().contains('No Activity found')) {
          errorMessage = 'Tidak ada aplikasi yang dapat membagikan foto ini';
        } else if (e.toString().contains('Permission denied')) {
          errorMessage = 'Izin ditolak untuk membagikan foto';
        } else {
          errorMessage = 'Gagal membagikan foto: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFEF4444),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: () => _sharePhoto(),
            ),
          ),
        );
      }
    }
  }

  void _extractText() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Mengekstrak teks dari foto...'),
            ],
          ),
        ),
      );

      // Navigate to text editor with current photo
      Navigator.pop(context); // Close loading dialog
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TextToEbookEditorScreen(
            imagePaths: [photo!.imagePath],
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengekstrak teks: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _deletePhoto() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Hapus Foto'),
            content: Text(
              'Apakah Anda yakin ingin menghapus "${photo!.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  _dataService.deletePhoto(photo!.id);
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close photo view

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Foto "${photo!.title}" berhasil dihapus'),
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
}
