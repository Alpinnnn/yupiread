import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/photo_model.dart';
import '../services/data_service.dart';

class PhotoPageViewScreen extends StatefulWidget {
  final String photoPageId;

  const PhotoPageViewScreen({super.key, required this.photoPageId});

  @override
  State<PhotoPageViewScreen> createState() => _PhotoPageViewScreenState();
}

class _PhotoPageViewScreenState extends State<PhotoPageViewScreen>
    with TickerProviderStateMixin {
  final DataService _dataService = DataService();
  PhotoPageModel? photoPage;
  bool _showBottomBar = false;
  int _currentPhotoIndex = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final TransformationController _transformationController =
      TransformationController();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    photoPage = _dataService.getPhotoPage(widget.photoPageId);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleBottomBar() {
    setState(() {
      _showBottomBar = !_showBottomBar;
    });

    if (_showBottomBar) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
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
      body: Stack(
        children: [
          // Main photo page view
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPhotoIndex = index;
              });
              _resetZoom();
            },
            itemCount: photoPage!.imagePaths.length,
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.1,
                  maxScale: 5.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  boundaryMargin: EdgeInsets.zero,
                  constrained: false,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Image.file(
                      File(photoPage!.imagePaths[index]),
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
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
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          // Photo navigation indicators
          if (photoPage!.photoCount > 1)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  photoPage!.photoCount,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentPhotoIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom sheet with photo page details and actions
          if (_showBottomBar)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _slideAnimation,
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
                                  _editPhotoPage();
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.add_photo_alternate,
                                label: 'Tambah Foto',
                                onTap: () {
                                  _toggleBottomBar();
                                  _addPhotoToPage();
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.share,
                                label: 'Bagikan',
                                onTap: () {
                                  _toggleBottomBar();
                                  _sharePhotoPage();
                                },
                              ),
                              _buildActionButton(
                                icon: Icons.delete,
                                label: 'Hapus',
                                color: Colors.red,
                                onTap: () {
                                  _toggleBottomBar();
                                  _deletePhotoPage();
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
        ],
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

  void _editPhotoPage() {
    // TODO: Implement edit photo page functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur edit akan segera hadir')),
    );
  }

  void _addPhotoToPage() {
    // TODO: Implement add photo to page functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur tambah foto akan segera hadir')),
    );
  }

  Future<void> _sharePhotoPage() async {
    try {
      final files = photoPage!.imagePaths.map((path) => XFile(path)).toList();

      String shareText = photoPage!.title;
      if (photoPage!.description.isNotEmpty) {
        shareText += '\n\n${photoPage!.description}';
      }
      shareText += '\n\n${photoPage!.photoCount} foto dibagikan dari YupiRead';

      await Share.shareXFiles(
        files,
        text: shareText,
        subject: photoPage!.title,
        sharePositionOrigin: Rect.fromLTWH(
          0,
          0,
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height / 2,
        ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Hapus Halaman Foto'),
            content: Text(
              'Apakah Anda yakin ingin menghapus "${photoPage!.title}"? Semua foto dalam halaman ini akan dihapus.',
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
                  Navigator.pop(context); // Close photo page view

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Halaman foto "${photoPage!.title}" berhasil dihapus',
                      ),
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
