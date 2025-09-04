import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:extended_image/extended_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/data_service.dart';
import '../models/photo_model.dart';
import '../l10n/app_localizations.dart';
import 'text_scanner_screen.dart';

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
  late AnimationController _bottomMenuAnimationController;
  late Animation<double> _bottomMenuAnimation;
  double _dragOffset = 0.0;
  double _bottomBarHeight = 300.0;
  final GlobalKey<ExtendedImageGestureState> _gestureKey =
      GlobalKey<ExtendedImageGestureState>();

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

    _bottomMenuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _bottomMenuAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bottomMenuAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bottomMenuAnimationController.dispose();
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
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              if (_showBottomBar) {
                // Closing bottom bar with animation
                _bottomMenuAnimationController.reverse().then((_) {
                  setState(() {
                    _showBottomBar = false;
                  });
                });
              } else {
                // Opening bottom bar with animation
                setState(() {
                  _showBottomBar = true;
                  _dragOffset = 0.0; // Reset to default position when opening
                });
                _bottomMenuAnimationController.forward();
              }
            },
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_showBottomBar) {
            _bottomMenuAnimationController.reverse().then((_) {
              setState(() {
                _showBottomBar = false;
              });
            });
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
                    cacheGesture:
                        false, // Disable gesture caching for better responsiveness
                    hitTestBehavior:
                        HitTestBehavior
                            .opaque, // Ensure all touch areas are responsive
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
                          child: CircularProgressIndicator(color: Colors.white),
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
                      _dragOffset = (_dragOffset - details.delta.dy).clamp(
                        -_bottomBarHeight,
                        0.0,
                      );
                    });
                  },
                  onPanEnd: (details) {
                    if (_dragOffset < -_bottomBarHeight * 0.5) {
                      // Close if dragged more than 50%
                      _bottomMenuAnimationController.reverse().then((_) {
                        setState(() {
                          _showBottomBar = false;
                        });
                      });
                    } else {
                      // Snap back to original position
                      setState(() {
                        _dragOffset = 0.0;
                      });
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _bottomMenuAnimation,
                    builder:
                        (context, child) => Transform.translate(
                          offset: Offset(
                            0,
                            (1 - _bottomMenuAnimation.value) * _bottomBarHeight,
                          ),
                          child: Opacity(
                            opacity: _bottomMenuAnimation.value,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                          if (photo!
                                              .description
                                              .isNotEmpty) ...[
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
                                                            BorderRadius.circular(
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
                                                          color: Color(
                                                            0xFF2563EB,
                                                          ),
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
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
                                            label:
                                                AppLocalizations.of(
                                                  context,
                                                ).edit,
                                            onTap: () {
                                              _bottomMenuAnimationController
                                                  .reverse()
                                                  .then((_) {
                                                    setState(() {
                                                      _showBottomBar = false;
                                                    });
                                                  });
                                              _editPhoto();
                                            },
                                          ),
                                          _buildActionButton(
                                            icon: Icons.share,
                                            label:
                                                AppLocalizations.of(
                                                  context,
                                                ).share,
                                            onTap: () {
                                              _bottomMenuAnimationController
                                                  .reverse()
                                                  .then((_) {
                                                    setState(() {
                                                      _showBottomBar = false;
                                                    });
                                                  });
                                              _sharePhoto();
                                            },
                                          ),
                                          _buildActionButton(
                                            icon: Icons.text_fields,
                                            label: 'Ekstrak Teks',
                                            onTap: () {
                                              _bottomMenuAnimationController
                                                  .reverse()
                                                  .then((_) {
                                                    setState(() {
                                                      _showBottomBar = false;
                                                    });
                                                  });
                                              _extractText();
                                            },
                                          ),
                                          _buildActionButton(
                                            icon: Icons.delete,
                                            label:
                                                AppLocalizations.of(
                                                  context,
                                                ).delete,
                                            color: Colors.red,
                                            onTap: () {
                                              _bottomMenuAnimationController
                                                  .reverse()
                                                  .then((_) {
                                                    setState(() {
                                                      _showBottomBar = false;
                                                    });
                                                  });
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
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color ?? Colors.white, size: 24),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color ?? Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
                  title: Text(
                    AppLocalizations.of(context).editPhoto,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
        // Show dialog to choose share format
        _showShareDialog();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan foto: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Bagikan Sebagai',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.image, color: Color(0xFF3B82F6)),
                  title: const Text('Foto'),
                  subtitle: const Text('Bagikan sebagai file gambar'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareAsPhoto();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.picture_as_pdf,
                    color: Color(0xFFEF4444),
                  ),
                  title: const Text('PDF'),
                  subtitle: const Text('Konversi ke PDF (1 foto / halaman)'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareAsPdf();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ],
          ),
    );
  }

  Future<void> _shareAsPhoto() async {
    try {
      // Create share text
      String shareText = photo!.title;
      if (photo!.description.isNotEmpty) {
        shareText += '\n\n${photo!.description}';
      }
      shareText += '\n\nDibagikan dari Yupiread';

      // Create XFile for sharing
      final xFile = XFile(
        photo!.imagePath,
        name: '${photo!.title}.jpg',
        mimeType: 'image/jpeg',
      );

      await Share.shareXFiles([xFile], text: shareText, subject: photo!.title);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto berhasil dibagikan'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan foto: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _shareAsPdf() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Mengkonversi ke PDF...'),
                ],
              ),
            ),
      );

      // Convert image to PDF
      final pdfPath = await _convertImageToPdf();

      // Close loading dialog
      Navigator.pop(context);

      if (pdfPath != null) {
        // Create share text
        String shareText = photo!.title;
        if (photo!.description.isNotEmpty) {
          shareText += '\n\n${photo!.description}';
        }
        shareText += '\n\nDibagikan dari Yupiread sebagai PDF';

        // Create XFile for sharing
        final xFile = XFile(
          pdfPath,
          name: '${photo!.title}.pdf',
          mimeType: 'application/pdf',
        );

        await Share.shareXFiles(
          [xFile],
          text: shareText,
          subject: '${photo!.title} - PDF',
        );

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF berhasil dibagikan'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } else {
        throw Exception('Gagal mengkonversi gambar ke PDF');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan sebagai PDF: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<String?> _convertImageToPdf() async {
    try {
      final pdf = pw.Document();
      final imageFile = File(photo!.imagePath);
      final imageBytes = await imageFile.readAsBytes();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                pw.MemoryImage(imageBytes),
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );

      // Save PDF to temporary location
      final appDir = await getApplicationDocumentsDirectory();
      final yupireadDir = Directory('${appDir.path}/Yupiread');
      if (!await yupireadDir.exists()) {
        await yupireadDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${yupireadDir.path}/${photo!.title}_$timestamp.pdf';

      final file = File(outputPath);
      await file.writeAsBytes(await pdf.save());

      return outputPath;
    } catch (e) {
      return null;
    }
  }

  void _extractText() async {
    try {
      // Navigate to text scanner with current photo
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => TextScannerScreen(
                imageFile: File(photo!.imagePath),
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

  void _deletePhoto() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(AppLocalizations.of(context).deletePhoto),
            content: Text(
              '${AppLocalizations.of(context).deleteConfirmation} "${photo!.title}"?',
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
                child: Text(AppLocalizations.of(context).delete),
              ),
            ],
          ),
    );
  }
}
