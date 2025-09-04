import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ebook_model.dart';
import '../services/data_service.dart';
import 'text_ebook_editor_screen.dart';

class JsonEbookReaderScreen extends StatefulWidget {
  final EbookModel ebook;

  const JsonEbookReaderScreen({super.key, required this.ebook});

  @override
  State<JsonEbookReaderScreen> createState() => _JsonEbookReaderScreenState();
}

class _JsonEbookReaderScreenState extends State<JsonEbookReaderScreen>
    with TickerProviderStateMixin {
  final QuillController _controller = QuillController.basic();
  final DataService _dataService = DataService.instance;
  EbookModel? ebook;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _showBottomBar = false;
  bool _showEbookInfo = false;
  late AnimationController _bottomMenuAnimationController;
  late Animation<double> _bottomMenuAnimation;
  double _dragOffset = 0.0;
  double _bottomBarHeight = 400.0;
  
  // Page tracking for JSON ebooks (simulated pages based on content)
  int _currentPage = 1;
  int _totalPages = 1;
  
  // Reading time tracking
  DateTime? _sessionStartTime;
  DateTime? _lastActiveTime;

  @override
  void initState() {
    super.initState();
    _loadDocument();
    _startReadingSession();

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
    _endReadingSession();
    _controller.dispose();
    _bottomMenuAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    try {
      final file = File(widget.ebook.filePath);
      if (!await file.exists()) {
        setState(() {
          _errorMessage = 'File tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      final jsonString = await file.readAsString();
      final documentData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Create QuillController from Delta data
      final deltaJson = documentData['delta'] as List<dynamic>;
      final document = Document.fromJson(deltaJson);

      _controller.document = document;

      setState(() {
        ebook = widget.ebook;
        _isLoading = false;
      });

      // Update last read time and calculate pages
      _calculatePages();
      _dataService.updateEbookProgress(widget.ebook.id, _currentPage);
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat dokumen: $e';
        _isLoading = false;
      });
    }
  }

  void _shareDocument() {
    if (ebook == null) return;

    Share.shareXFiles([XFile(widget.ebook.filePath)], text: 'Berbagi Ebook: ${ebook!.title}');
  }

  void _calculatePages() {
    // Estimate pages based on content length (similar to Word reader)
    final plainText = _controller.document.toPlainText();
    final wordCount = plainText.split(RegExp(r'\s+')).length;
    _totalPages = (wordCount / 500).ceil().clamp(1, double.infinity).toInt();
    
    if (ebook != null && ebook!.totalPages != _totalPages) {
      _dataService.updateEbookTotalPages(widget.ebook.id, _totalPages);
    }
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
  
  void _navigateToEditor() async {
    if (ebook == null) return;
    
    // Get the current content from the quill controller
    final currentContent = _controller.document.toPlainText();
    
    // Navigate to the text ebook editor with current content
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TextEbookEditorScreen(
          initialText: currentContent,
          initialTitle: ebook!.title,
          existingFilePath: ebook!.filePath,
        ),
      ),
    );
    
    // If the editor returns a result, refresh the ebook data
    if (result == true) {
      setState(() {
        ebook = _dataService.getEbook(widget.ebook.id);
        _loadDocument();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ebook berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showEditEbookDialog() {
    final TextEditingController titleController = TextEditingController(
      text: ebook!.title,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: ebook!.description,
    );
    List<String> selectedTags = List.from(ebook!.tags);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Ebook',
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
                    labelText: 'Judul Ebook',
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
                  'Tag:',
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
                      selectedColor: const Color(0xFF2563EB).withOpacity(0.2),
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
                final newDescription = descriptionController.text.trim();

                if (newTitle.isNotEmpty) {
                  _dataService.updateEbook(
                    id: ebook!.id,
                    title: newTitle,
                    description: newDescription,
                    tags: selectedTags,
                  );

                  setState(() {
                    ebook = _dataService.getEbook(widget.ebook.id);
                  });

                  Navigator.pop(context);
                  _bottomMenuAnimationController.reverse().then((_) {
                    setState(() {
                      _showBottomBar = false;
                    });
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ebook berhasil diperbarui'),
                      backgroundColor: Colors.green,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }



  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              widget.ebook.title,
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
              Icons.more_vert,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () {
              if (_showBottomBar) {
                _bottomMenuAnimationController.reverse().then((_) {
                  setState(() {
                    _showBottomBar = false;
                  });
                });
              } else {
                setState(() {
                  _showBottomBar = true;
                  _dragOffset = 0.0;
                });
                _bottomMenuAnimationController.forward();
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
                  value: ebook?.progress ?? 0.0,
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
                      '${ebook?.progressPercentage ?? "0%"} selesai',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    Text(
                      'Terakhir dibaca: ${ebook?.timeAgo ?? "Baru saja"}',
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
          // Content area
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_showBottomBar) {
                  _bottomMenuAnimationController.reverse().then((_) {
                    setState(() {
                      _showBottomBar = false;
                    });
                  });
                }
                _updateLastActiveTime();
              },
              child: Stack(
                children: [
                  // Main content area with full height
                  Positioned.fill(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _hasError
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage ?? 'Terjadi kesalahan saat memuat dokumen',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                width: double.infinity,
                                height: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: QuillEditor.basic(
                                  controller: _controller,
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
                          builder: (context, child) => Transform.translate(
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

                                      // Ebook details
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ebook!.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Halaman $_currentPage dari $_totalPages • ${ebook!.timeAgo}',
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
                                                  borderRadius: BorderRadius.circular(8),
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
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Progress: ${ebook?.progressPercentage ?? "0%"}',
                                                      style: TextStyle(
                                                        color: Colors.grey[300],
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    if (ebook!.description.isNotEmpty) ...[
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Deskripsi: ${ebook!.description}',
                                                        style: TextStyle(
                                                          color: Colors.grey[300],
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                    if (ebook!.tags.isNotEmpty) ...[
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
                                                        children: ebook!.tags.map((tag) {
                                                          return Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFF2563EB).withOpacity(0.2),
                                                              borderRadius: BorderRadius.circular(12),
                                                              border: Border.all(
                                                                color: const Color(0xFF2563EB).withOpacity(0.5),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              tag,
                                                              style: const TextStyle(
                                                                color: Color(0xFF2563EB),
                                                                fontSize: 11,
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
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildActionButton(
                                              icon: Icons.edit,
                                              label: 'Edit Ebook',
                                              onTap: _navigateToEditor,
                                            ),
                                            _buildActionButton(
                                              icon: Icons.share,
                                              label: 'Bagikan Ebook',
                                              onTap: _shareDocument,
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
          ),
        ],
      ),
      bottomNavigationBar: !_showBottomBar
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
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
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage = (_currentPage - 1).clamp(1, _totalPages);
                            });
                            _updateLastActiveTime();
                          }
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
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                    onPressed: _currentPage < _totalPages
                        ? () {
                            setState(() {
                              _currentPage = (_currentPage + 1).clamp(1, _totalPages);
                            });
                            _updateLastActiveTime();
                          }
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
}
