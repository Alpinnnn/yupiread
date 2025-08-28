import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
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
  final DataService _dataService = DataService.instance;
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
  bool _hasLoggedCompletion = false; // Track if completion has been logged
  late AnimationController _animationController;
  late Animation<double> _zoomAnimation;
  late AnimationController _zoomAnimationController;
  
  // Throttling variables
  DateTime _lastGestureUpdate = DateTime.now();
  DateTime _lastZoomUpdate = DateTime.now();
  DateTime _lastPanUpdate = DateTime.now();
  static const Duration _gestureThrottle = Duration(milliseconds: 16); // 60fps
  static const Duration _zoomThrottle = Duration(milliseconds: 50);
  static const Duration _panThrottle = Duration(milliseconds: 33); // 30fps for pan
  
  // Viewport tracking to prevent unnecessary rendering
  double _lastViewportZoom = 1.0;
  double _dragOffset = 0.0;
  double _bottomBarHeight = 400.0;

  // Reading time tracking
  DateTime? _sessionStartTime;
  DateTime? _lastActiveTime;

  // Pan/drag tracking for zoomed content
  Offset _panOffset = Offset.zero;
  Offset _initialPanOffset = Offset.zero;

  // Double tap zoom tracking
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _loadEbook();
    _startReadingSession();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _zoomAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _zoomAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _zoomAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _zoomAnimation.addListener(() {
      // Remove setState to prevent excessive rebuilds during animation
      _currentZoomLevel = _zoomAnimation.value;
      // Only update PDF viewer zoom level without rebuilding entire widget
      if (_pdfViewerController.zoomLevel != _currentZoomLevel) {
        _pdfViewerController.zoomLevel = _currentZoomLevel;
      }
    });
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
    // Batch state updates to reduce rebuilds
    if (_currentPage != pageNumber || pageNumber > _maxPageReached) {
      setState(() {
        _currentPage = pageNumber;
        if (pageNumber > _maxPageReached) {
          _maxPageReached = pageNumber;
        }
      });
    }

    // Get old progress before updating
    final oldProgress = _ebook?.progress ?? 0.0;
    
    // Always update progress in data service to save current position
    _dataService.updateEbookProgress(widget.ebookId, _maxPageReached);
    // Refresh ebook data to get updated progress - avoid unnecessary setState
    final updatedEbook = _dataService.getEbook(widget.ebookId);
    if (updatedEbook != null && updatedEbook.progress != _ebook?.progress) {
      setState(() {
        _ebook = updatedEbook;
      });
      
      // Check if ebook just reached 100% completion
      final newProgress = updatedEbook.progress;
      print('DEBUG: Progress check - oldProgress: $oldProgress, newProgress: $newProgress, totalPages: ${updatedEbook.totalPages}, currentPage: ${updatedEbook.currentPage}');
      
      // Log completion for single-page ebooks when first opened, or multi-page when reaching 100%
      bool shouldLogCompletion = false;
      
      if (updatedEbook.totalPages == 1 && !_hasLoggedCompletion) {
        // Single-page ebook: log completion when first opened
        shouldLogCompletion = true;
        _hasLoggedCompletion = true;
      } else if (updatedEbook.totalPages > 1 && oldProgress < 1.0 && newProgress >= 1.0) {
        // Multi-page ebook: log completion when reaching 100%
        shouldLogCompletion = true;
        _hasLoggedCompletion = true;
      }
      
      if (shouldLogCompletion) {
        print('DEBUG: Ebook completion detected! Logging activity...');
        // Log completion activity
        _dataService.logEbookActivity(
          title: 'Ebook "${updatedEbook.title}" Telah Dibaca',
          description: 'Ebook telah selesai dibaca hingga 100%',
          type: ActivityType.ebookCompleted,
        );
        
        print('DEBUG: Activity logged successfully');
        
        // Show completion message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Selamat! Ebook "${updatedEbook.title}" telah selesai dibaca!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
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
    
    // For single-page ebooks, ensure progress is updated immediately
    if (_totalPages == 1 && _ebook != null && _ebook!.currentPage == 0) {
      // Update progress to page 1 for single-page ebooks
      _updateProgress(1);
    }
  }

  void _zoomOut() {
    final newZoomLevel = (_currentZoomLevel - 0.2).clamp(0.5, 3.0);
    setState(() {
      _currentZoomLevel = newZoomLevel;
    });
    // Use direct zoom level update to preserve position
    _pdfViewerController.zoomLevel = newZoomLevel;
  }

  void _zoomIn() {
    final newZoomLevel = (_currentZoomLevel + 0.2).clamp(0.5, 3.0);
    setState(() {
      _currentZoomLevel = newZoomLevel;
    });
    // Use direct zoom level update to preserve position
    _pdfViewerController.zoomLevel = newZoomLevel;
  }

  void _animateZoomTo(double targetZoom) {
    _zoomAnimation = Tween<double>(
      begin: _currentZoomLevel,
      end: targetZoom,
    ).animate(
      CurvedAnimation(
        parent: _zoomAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _zoomAnimationController.reset();
    _zoomAnimationController.forward();
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (_isZoomed) {
      // Zoom out to fit page
      setState(() {
        _currentZoomLevel = 1.0;
        _isZoomed = false;
        _panOffset = Offset.zero;
      });
      _pdfViewerController.zoomLevel = 1.0;
    } else {
      // Zoom in to 2x - let PDF viewer handle positioning
      setState(() {
        _currentZoomLevel = 2.0;
        _isZoomed = true;
        _panOffset = Offset.zero;
      });
      _pdfViewerController.zoomLevel = 2.0;
    }
  }

  void _handleScrollZoom(PointerScrollEvent event) {
    if (HardwareKeyboard.instance.isLogicalKeyPressed(
          LogicalKeyboardKey.controlLeft,
        ) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(
          LogicalKeyboardKey.controlRight,
        )) {
      final delta = event.scrollDelta.dy;
      final zoomDelta = delta > 0 ? -0.1 : 0.1;
      final newZoomLevel = (_currentZoomLevel + zoomDelta).clamp(0.5, 3.0);

      setState(() {
        _currentZoomLevel = newZoomLevel;
      });
      // Use direct zoom level update to preserve position
      _pdfViewerController.zoomLevel = newZoomLevel;

      if (newZoomLevel <= 1.0) {
        _isZoomed = false;
      } else {
        _isZoomed = true;
      }
    }
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _ebook!.title,
              style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Halaman $_currentPage dari $_totalPages',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.bookmark_border,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () {
              // TODO: Implement bookmark functionality
            },
          ),
          IconButton(
            icon: Icon(
              Icons.zoom_out,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () => _zoomOut(),
            tooltip: 'Zoom Out',
          ),
          Text(
            '${(_currentZoomLevel * 100).round()}%',
            style: TextStyle(
              color: Theme.of(context).appBarTheme.foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.zoom_in,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () => _zoomIn(),
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () {
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
                  value: _ebook?.progress ?? 0.0,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                  minHeight: 4,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_ebook?.progressPercentage ?? "0%"} selesai',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    Text(
                      'Terakhir dibaca: ${_ebook!.timeAgo}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
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
                Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      _handleScrollZoom(event);
                    }
                  },
                  child: GestureDetector(
                    onTap: () {
                      if (_showBottomBar) {
                        setState(() {
                          _showBottomBar = false;
                        });
                        _animationController.reverse();
                      }
                    },
                    onTapDown: (details) {
                      // Tap position handling for future use
                    },
                    onDoubleTapDown: _handleDoubleTap,
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
                          final now = DateTime.now();
                          
                          // Throttle gesture updates to reduce JNI calls
                          if (now.difference(_lastGestureUpdate) < _gestureThrottle) {
                            return;
                          }
                          _lastGestureUpdate = now;
                          
                          // Handle pinch-to-zoom with throttling
                          if (details.scale != 1.0) {
                            final newZoomLevel = (_initialZoomLevel *
                                    details.scale)
                                .clamp(0.5, 3.0);
                            
                            // Only update if zoom changed significantly
                            if ((newZoomLevel - _currentZoomLevel).abs() > 0.05) {
                              setState(() {
                                _currentZoomLevel = newZoomLevel;
                                _isZoomed = _currentZoomLevel > 1.0;
                              });
                              
                              // Debounce PDF controller updates
                              Future.microtask(() {
                                _pdfViewerController.zoomLevel = _currentZoomLevel;
                              });
                            }
                          }

                          // Handle drag/pan when zoomed in with throttling
                          if (_currentZoomLevel > 1.0 &&
                              details.focalPointDelta != Offset.zero) {
                            final panNow = DateTime.now();
                            
                            // Throttle pan updates to reduce rendering calls
                            if (panNow.difference(_lastPanUpdate) >= _panThrottle) {
                              _lastPanUpdate = panNow;
                              
                              final newPanOffset = _initialPanOffset + details.focalPointDelta;
                              
                              // Only update if pan distance is significant
                              if ((newPanOffset - _panOffset).distance > 5.0) {
                                setState(() {
                                  _panOffset = newPanOffset;
                                });
                              }
                            }
                          }
                        },
                        child: Transform.translate(
                          offset:
                              _currentZoomLevel > 1.0
                                  ? _panOffset
                                  : Offset.zero,
                          child: SfPdfViewer.file(
                            File(_ebook!.filePath),
                            controller: _pdfViewerController,
                            onPageChanged: (PdfPageChangedDetails details) {
                              // Debounce page changes to reduce excessive calls
                              Future.microtask(() {
                                _updateProgress(details.newPageNumber);
                                // Reset zoom to 100% when page changes
                                if (_isZoomed || _currentZoomLevel != 1.0) {
                                  setState(() {
                                    _currentZoomLevel = 1.0;
                                    _isZoomed = false;
                                    _panOffset = Offset.zero;
                                  });
                                  _pdfViewerController.zoomLevel = 1.0;
                                }
                              });
                            },
                            onDocumentLoaded: (
                              PdfDocumentLoadedDetails details,
                            ) {
                              setState(() {
                                _totalPages = details.document.pages.count;
                              });
                            },
                            onZoomLevelChanged: (PdfZoomDetails details) {
                              final now = DateTime.now();
                              
                              // Throttle zoom level changes
                              if (now.difference(_lastZoomUpdate) < _zoomThrottle) {
                                return;
                              }
                              _lastZoomUpdate = now;
                              
                              // Debounce zoom changes to prevent excessive rebuilds
                              Future.microtask(() {
                                // Only update if zoom changed significantly
                                if ((details.newZoomLevel - _currentZoomLevel).abs() > 0.05) {
                                  // Check if viewport changed significantly to prevent unnecessary text re-rendering
                                  final viewportChanged = (details.newZoomLevel - _lastViewportZoom).abs() > 0.1;
                                  
                                  if (viewportChanged) {
                                    _lastViewportZoom = details.newZoomLevel;
                                    
                                    setState(() {
                                      _currentZoomLevel = details.newZoomLevel;
                                      _isZoomed = details.newZoomLevel > 1.0;
                                    });
                                  }
                                }
                                _updateLastActiveTime();
                              });
                            },
                            enableDoubleTapZooming:
                                false, // Disable default double tap
                            enableTextSelection: false, // Disable text selection to reduce rendering
                            canShowScrollHead: false, // Hide scroll indicator
                            canShowScrollStatus: false, // Hide scroll status
                            canShowPaginationDialog: false, // Disable pagination dialog
                            enableDocumentLinkAnnotation: false, // Disable link annotations
                            initialZoomLevel: _currentZoomLevel,
                            pageLayoutMode: PdfPageLayoutMode.single,
                            scrollDirection: PdfScrollDirection.vertical,
                            // Optimize rendering performance
                            interactionMode: PdfInteractionMode.pan,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom sheet menu
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
                          setState(() {
                            _showBottomBar = false;
                          });
                          _animationController.reverse();
                        } else {
                          // Snap back to original position
                          setState(() {
                            _dragOffset = 0.0;
                          });
                        }
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                'Progress: ${_ebook?.progressPercentage ?? "0%"}',
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
                                                              color:
                                                                  const Color(
                                                                    0xFF2563EB,
                                                                  ).withOpacity(
                                                                    0.5,
                                                                  ),
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
                  color:
                      Theme.of(
                        context,
                      ).bottomNavigationBarTheme.backgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                      icon: Icon(
                        Icons.chevron_left,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      iconSize: 32,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _currentPage < _totalPages
                              ? () => _pdfViewerController.nextPage()
                              : null,
                      icon: Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).iconTheme.color,
                      ),
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
    _zoomAnimationController.dispose();
    super.dispose();
  }
}
