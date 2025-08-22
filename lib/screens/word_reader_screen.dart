import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'dart:io';
import '../models/ebook_model.dart';
import '../services/data_service.dart';

class WordReaderScreen extends StatefulWidget {
  final String ebookId;

  const WordReaderScreen({super.key, required this.ebookId});

  @override
  State<WordReaderScreen> createState() => _WordReaderScreenState();
}

class _WordReaderScreenState extends State<WordReaderScreen>
    with TickerProviderStateMixin {
  final DataService _dataService = DataService();
  EbookModel? _ebook;
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  List<String> _pages = [];
  bool _showEbookInfo = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();

  // Reading time tracking
  DateTime? _sessionStartTime;

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
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _endReadingSession();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startReadingSession() {
    _sessionStartTime = DateTime.now();
  }

  void _endReadingSession() {
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      final minutes = sessionDuration.inMinutes;
      if (minutes > 0) {
        _dataService.addReadingTime(minutes);
      }
    }
  }

  Future<void> _loadEbook() async {
    final ebook = _dataService.getEbook(widget.ebookId);
    if (ebook != null) {
      setState(() {
        _ebook = ebook;
        _currentPage = ebook.currentPage > 0 ? ebook.currentPage : 1;
        _totalPages = ebook.totalPages;
      });

      await _loadWordContent();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadWordContent() async {
    try {
      final file = File(_ebook!.filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        
        // Debug: Print file info
        print('Word file size: ${bytes.length} bytes');
        
        String text = docxToText(bytes);
        
        // Clean up XML tags if present
        if (text.startsWith('<?xml')) {
          // Try to extract text content from XML
          final RegExp textRegex = RegExp(r'<w:t[^>]*>([^<]*)</w:t>');
          final matches = textRegex.allMatches(text);
          if (matches.isNotEmpty) {
            text = matches.map((match) => match.group(1) ?? '').join(' ');
          } else {
            // Fallback: remove all XML tags
            text = text.replaceAll(RegExp(r'<[^>]*>'), ' ')
                      .replaceAll(RegExp(r'\s+'), ' ')
                      .trim();
          }
        }
        
        // Debug: Print extracted text info
        print('Cleaned text length: ${text.length} characters');
        print('First 100 characters: ${text.length > 100 ? text.substring(0, 100) : text}');
        
        // Split content into pages (approximately 1000 characters per page)
        _splitContentIntoPages(text);
      } else {
        print('Word file does not exist: ${_ebook!.filePath}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File Word tidak ditemukan'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading Word content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat konten Word: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _splitContentIntoPages(String content) {
    const int charactersPerPage = 1000;
    final List<String> pages = [];
    
    // Handle empty content
    if (content.isEmpty) {
      pages.add('Dokumen kosong atau tidak dapat dibaca.');
    } else {
      for (int i = 0; i < content.length; i += charactersPerPage) {
        final end = (i + charactersPerPage < content.length) 
            ? i + charactersPerPage 
            : content.length;
        pages.add(content.substring(i, end));
      }
    }
    
    // Debug: Print page info
    print('Total pages created: ${pages.length}');
    if (pages.isNotEmpty) {
      print('First page preview: ${pages[0].length > 50 ? pages[0].substring(0, 50) : pages[0]}...');
      print('Page 1 full content: ${pages[0]}');
    }
    
    setState(() {
      _pages = pages;
      _totalPages = pages.length;
      if (_totalPages > 0 && _currentPage == 0) {
        _currentPage = 1; // Ensure current page is set
      }
    });
    
    print('After setState - _pages.length: ${_pages.length}, _totalPages: $_totalPages, _currentPage: $_currentPage');
    
    // Update total pages in data service
    _dataService.updateEbookTotalPages(widget.ebookId, _totalPages);
  }

  void _updateProgress(int pageNumber) {
    setState(() {
      _currentPage = pageNumber;
    });

    // Update progress in data service
    _dataService.updateEbookProgress(widget.ebookId, pageNumber);
    
    // Refresh ebook data
    final updatedEbook = _dataService.getEbook(widget.ebookId);
    if (updatedEbook != null) {
      setState(() {
        _ebook = updatedEbook;
      });
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _updateProgress(page);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _goToPage(_currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _goToPage(_currentPage - 1);
    }
  }

  void _showJumpToPageDialog() {
    final TextEditingController pageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lompat ke Halaman'),
        content: TextField(
          controller: pageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Nomor halaman (1-$_totalPages)',
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
              final page = int.tryParse(pageController.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                _goToPage(page);
                Navigator.pop(context);
              }
            },
            child: const Text('Lompat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_ebook == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Ebook tidak ditemukan'),
        ),
      );
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
        title: Text(
          _ebook!.title,
          style: const TextStyle(color: Colors.black, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: () {
              setState(() {
                _showEbookInfo = !_showEbookInfo;
              });
              if (_showEbookInfo) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.black),
            onPressed: _showJumpToPageDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Progress bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _ebook?.progress ?? 0.0,
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
                          '${_ebook?.progressPercentage ?? "0%"} selesai',
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
              // Content
              Expanded(
                child: _pages.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: SelectableText(
                            _pages[_currentPage - 1],
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Text('Konten tidak dapat dimuat'),
                      ),
              ),
              // Navigation controls
              Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _currentPage > 1 ? _previousPage : null,
                      icon: const Icon(Icons.chevron_left),
                      iconSize: 32,
                    ),
                    Text(
                      'Halaman $_currentPage dari $_totalPages',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    IconButton(
                      onPressed: _currentPage < _totalPages ? _nextPage : null,
                      icon: const Icon(Icons.chevron_right),
                      iconSize: 32,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Ebook info overlay
          if (_showEbookInfo)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showEbookInfo = false;
                });
                _animationController.reverse();
              },
              child: Container(
                color: Colors.black54,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progress: ${_ebook?.progressPercentage ?? "0%"}',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 13,
                            ),
                          ),
                          if (_ebook!.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _ebook!.description,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 13,
                              ),
                            ),
                          ],
                          if (_ebook!.tags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              children: _ebook!.tags
                                  .map((tag) => Chip(
                                        label: Text(
                                          tag,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        backgroundColor: Colors.grey[700],
                                        labelStyle: TextStyle(color: Colors.grey[300]),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
