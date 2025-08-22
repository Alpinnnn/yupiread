import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import '../models/ebook_model.dart';
import '../models/activity_type.dart';
import '../services/data_service.dart';

class EbookReaderScreen extends StatefulWidget {
  final String ebookId;

  const EbookReaderScreen({super.key, required this.ebookId});

  @override
  State<EbookReaderScreen> createState() => _EbookReaderScreenState();
}

class _EbookReaderScreenState extends State<EbookReaderScreen>
    with TickerProviderStateMixin {
  final DataService _dataService = DataService();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  EbookModel? _ebook;
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  double _currentZoomLevel = 1.0;
  double _initialZoomLevel = 1.0;
  int _maxPageReached = 1; // Track maximum page reached
  bool _showBottomBar = false;
  bool _showEbookInfo = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  // Reading time tracking
  DateTime? _sessionStartTime;
  DateTime? _lastActiveTime;

  // Pan/drag tracking for zoomed content
  Offset _panOffset = Offset.zero;
  Offset _initialPanOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadEbook();
    _startReadingSession();

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

  void _loadEbook() {
    final ebook = _dataService.getEbook(widget.ebookId);
    if (ebook != null) {
      setState(() {
        _ebook = ebook;
        _currentPage = ebook.currentPage > 0 ? ebook.currentPage : 1;
        _maxPageReached = ebook.currentPage > 0 ? ebook.currentPage : 1;
        _isLoading = false;
      });

      // Navigate to last read page after a short delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ebook.currentPage > 1) {
          _pdfViewerController.jumpToPage(ebook.currentPage);
        }
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _updateProgress(int pageNumber) {
    // Update current page
    setState(() {
      _currentPage = pageNumber;
      // Only update max page if we've progressed further
      if (pageNumber > _maxPageReached) {
        _maxPageReached = pageNumber;
      }
    });

    // Update progress in data service only if we've reached a new maximum
    if (pageNumber >= _maxPageReached) {
      _dataService.updateEbookProgress(widget.ebookId, pageNumber);
      // Refresh ebook data to get updated progress
      final updatedEbook = _dataService.getEbook(widget.ebookId);
      if (updatedEbook != null) {
        setState(() {
          _ebook = updatedEbook;
        });
      }
    }

    _updateLastActiveTime();
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _totalPages = details.document.pages.count;
    });

    // Update total pages in the ebook model if different
    if (_ebook != null && _ebook!.totalPages != _totalPages) {
      _dataService.updateEbookTotalPages(widget.ebookId, _totalPages);
      setState(() {
        _ebook = _ebook!.copyWith(totalPages: _totalPages);
      });
    }
  }

  void _zoomOut() {
    setState(() {
      _currentZoomLevel = (_currentZoomLevel - 0.2).clamp(0.5, 3.0);
    });
    _pdfViewerController.zoomLevel = _currentZoomLevel;
  }

  void _zoomIn() {
    setState(() {
      _currentZoomLevel = (_currentZoomLevel + 0.2).clamp(0.5, 3.0);
    });
    _pdfViewerController.zoomLevel = _currentZoomLevel;
  }

  void _fitToWidth() {
    setState(() {
      _currentZoomLevel = 1.2; // Approximate fit to width
    });
    _pdfViewerController.zoomLevel = _currentZoomLevel;
  }

  void _fitToPage() {
    setState(() {
      _currentZoomLevel = 1.0; // Fit to page
    });
    _pdfViewerController.zoomLevel = _currentZoomLevel;
  }

  void _resetZoom() {
    setState(() {
      _currentZoomLevel = 1.0;
    });
    _pdfViewerController.zoomLevel = _currentZoomLevel;
  }

  void _startReadingSession() {
    _sessionStartTime = DateTime.now();
    _lastActiveTime = DateTime.now();
  }

  void _endReadingSession() {
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      final readingMinutes = sessionDuration.inMinutes;

      if (readingMinutes > 0) {
        _dataService.addReadingTime(readingMinutes);
      }
    }
  }

  void _updateLastActiveTime() {
    _lastActiveTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _ebook == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _ebook!.title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Halaman $_currentPage dari $_totalPages',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.black),
            onPressed: () {
              // TODO: Implement bookmark functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.black),
            onPressed: () => _zoomOut(),
            tooltip: 'Zoom Out',
          ),
          Text(
            '${(_currentZoomLevel * 100).round()}%',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.black),
            onPressed: () => _zoomIn(),
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              setState(() {
                _showBottomBar = !_showBottomBar;
              });
              if (_showBottomBar) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _totalPages > 0 ? _maxPageReached / _totalPages : 0.0,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF2563EB),
                  ),
                  minHeight: 4,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_totalPages > 0 ? ((_maxPageReached / _totalPages) * 100).round() : 0}% selesai',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'Terakhir dibaca: ${_ebook!.timeAgo}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // PDF Viewer
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_showBottomBar) {
                      setState(() {
                        _showBottomBar = false;
                      });
                      _animationController.reverse();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: GestureDetector(
                      onScaleStart: (details) {
                        // Store initial zoom level and pan position for gestures
                        _initialZoomLevel = _currentZoomLevel;
                        _initialPanOffset = _panOffset;
                      },
                      onScaleUpdate: (details) {
                        // Handle pinch-to-zoom
                        if (details.scale != 1.0) {
                          final newZoomLevel = (_initialZoomLevel *
                                  details.scale)
                              .clamp(0.5, 3.0);
                          setState(() {
                            _currentZoomLevel = newZoomLevel;
                          });
                          _pdfViewerController.zoomLevel = _currentZoomLevel;
                        }

                        // Handle drag/pan when zoomed in (using focalPointDelta)
                        if (_currentZoomLevel > 1.0 &&
                            details.focalPointDelta != Offset.zero) {
                          setState(() {
                            _panOffset =
                                _initialPanOffset + details.focalPointDelta;
                          });
                        }
                      },
                      child: Transform.translate(
                        offset:
                            _currentZoomLevel > 1.0 ? _panOffset : Offset.zero,
                        child: SfPdfViewer.file(
                          File(_ebook!.filePath),
                          controller: _pdfViewerController,
                          onPageChanged: (PdfPageChangedDetails details) {
                            _updateProgress(details.newPageNumber);
                          },
                          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                            setState(() {
                              _totalPages = details.document.pages.count;
                            });
                          },
                          onZoomLevelChanged: (PdfZoomDetails details) {
                            setState(() {
                              _currentZoomLevel = details.newZoomLevel;
                            });
                            // Reset pan offset when zoom level changes
                            if (_currentZoomLevel <= 1.0) {
                              _panOffset = Offset.zero;
                            }
                            _updateLastActiveTime();
                          },
                          enableDoubleTapZooming: true,
                          enableTextSelection: true,
                          canShowScrollHead: false, // Hide scroll indicator
                          canShowScrollStatus: false, // Hide scroll status
                          initialZoomLevel: _currentZoomLevel,
                          pageLayoutMode: PdfPageLayoutMode.single,
                          scrollDirection: PdfScrollDirection.vertical,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom sheet menu
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

                              // Ebook details
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _ebook!.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Halaman $_currentPage dari $_totalPages • ${_ebook!.timeAgo}',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),

                                    // Expandable info section
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _showEbookInfo = !_showEbookInfo;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.info_outline,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Info Detail Ebook',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(
                                              _showEbookInfo
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    if (_showEbookInfo) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Progress: ${_totalPages > 0 ? ((_maxPageReached / _totalPages) * 100).round() : 0}%',
                                              style: TextStyle(
                                                color: Colors.grey[300],
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (_ebook!
                                                .description
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                'Deskripsi: ${_ebook!.description}',
                                                style: TextStyle(
                                                  color: Colors.grey[300],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                            if (_ebook!.tags.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                'Tags:',
                                                style: TextStyle(
                                                  color: Colors.grey[300],
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children:
                                                    _ebook!.tags.map((tag) {
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
                                                          style:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xFF2563EB,
                                                                ),
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                      );
                                                    }).toList(),
                                              ),
                                            ],
                                          ],
                                        ),
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
                                      icon: Icons.skip_next,
                                      label: 'Loncat Halaman',
                                      onTap: _showJumpToPageDialog,
                                    ),
                                    _buildActionButton(
                                      icon: Icons.fit_screen,
                                      label: 'Sesuaikan Lebar',
                                      onTap: _fitToWidth,
                                    ),
                                    _buildActionButton(
                                      icon: Icons.fullscreen,
                                      label: 'Sesuaikan Halaman',
                                      onTap: _fitToPage,
                                    ),
                                    _buildActionButton(
                                      icon: Icons.refresh,
                                      label: 'Reset Zoom',
                                      onTap: _resetZoom,
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
          ),
        ],
      ),
      bottomNavigationBar:
          !_showBottomBar
              ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed:
                          _currentPage > 1
                              ? () => _pdfViewerController.previousPage()
                              : null,
                      icon: const Icon(Icons.chevron_left),
                      iconSize: 32,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _currentPage < _totalPages
                              ? () => _pdfViewerController.nextPage()
                              : null,
                      icon: const Icon(Icons.chevron_right),
                      iconSize: 32,
                    ),
                  ],
                ),
              )
              : null,
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showJumpToPageDialog() {
    final TextEditingController pageController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Loncat ke Halaman'),
            content: TextField(
              controller: pageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nomor Halaman (1-$_totalPages)',
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final pageNumber = int.tryParse(pageController.text);
                  if (pageNumber != null &&
                      pageNumber >= 1 &&
                      pageNumber <= _totalPages) {
                    _pdfViewerController.jumpToPage(pageNumber);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Masukkan nomor halaman yang valid (1-$_totalPages)',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Loncat'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _endReadingSession();
    _pdfViewerController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
