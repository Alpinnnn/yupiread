import 'package:flutter/material.dart';
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

class _EbookReaderScreenState extends State<EbookReaderScreen> {
  final DataService _dataService = DataService();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  EbookModel? _ebook;
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadEbook();
  }

  void _loadEbook() {
    final ebook = _dataService.getEbook(widget.ebookId);
    if (ebook != null) {
      setState(() {
        _ebook = ebook;
        _currentPage = ebook.currentPage;
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

  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() {
      _currentPage = details.newPageNumber;
    });

    // Update progress in the ebook model
    if (_ebook != null) {
      final updatedEbook = _ebook!.copyWith(
        currentPage: _currentPage,
        lastReadAt: DateTime.now(),
      );

      // Update in data service
      _dataService.updateEbookProgress(widget.ebookId, _currentPage);

      // Log reading activity
      _dataService.logEbookActivity(
        title: 'Membaca "${_ebook!.title}"',
        description: 'Melanjutkan membaca hingga halaman $_currentPage',
        type: ActivityType.ebookRead,
      );

      setState(() {
        _ebook = updatedEbook;
      });
    }
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              switch (value) {
                case 'info':
                  _showEbookInfo();
                  break;
                case 'jump':
                  _showJumpToPageDialog();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16),
                        SizedBox(width: 8),
                        Text('Info Ebook'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'jump',
                    child: Row(
                      children: [
                        Icon(Icons.skip_next, size: 16),
                        SizedBox(width: 8),
                        Text('Loncat ke Halaman'),
                      ],
                    ),
                  ),
                ],
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
                  value: _ebook!.progress,
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
                      '${_ebook!.progressPercentage} selesai',
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
            child: SfPdfViewer.file(
              File(_ebook!.filePath),
              controller: _pdfViewerController,
              onPageChanged: _onPageChanged,
              onDocumentLoaded: _onDocumentLoaded,
              enableDoubleTapZooming: true,
              enableTextSelection: true,
              canShowScrollHead: true,
              canShowScrollStatus: true,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      ),
    );
  }

  void _showEbookInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Info Ebook'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Judul: ${_ebook!.title}'),
                const SizedBox(height: 8),
                Text('Total Halaman: ${_ebook!.totalPages}'),
                const SizedBox(height: 8),
                Text('Progress: ${_ebook!.progressPercentage}'),
                const SizedBox(height: 8),
                Text('Terakhir Dibaca: ${_ebook!.timeAgo}'),
                if (_ebook!.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Deskripsi: ${_ebook!.description}'),
                ],
                if (_ebook!.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Tag: ${_ebook!.tags.join(', ')}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
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
    _pdfViewerController.dispose();
    super.dispose();
  }
}
