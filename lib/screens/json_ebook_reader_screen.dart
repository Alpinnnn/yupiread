import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:share_plus/share_plus.dart';
import '../services/data_service.dart';
import '../models/ebook_model.dart';
import 'text_ebook_editor_screen.dart';

class JsonEbookReaderScreen extends StatefulWidget {
  final EbookModel ebook;

  const JsonEbookReaderScreen({super.key, required this.ebook});

  @override
  State<JsonEbookReaderScreen> createState() => _JsonEbookReaderScreenState();
}

class _JsonEbookReaderScreenState extends State<JsonEbookReaderScreen> {
  late QuillController _quillController;
  final ScrollController _scrollController = ScrollController();
  final DataService _dataService = DataService.instance;

  Map<String, dynamic>? _documentData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _quillController.dispose();
    _scrollController.dispose();
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

      _quillController = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );

      setState(() {
        _documentData = documentData;
        _isLoading = false;
      });

      // Update last read time
      _dataService.updateEbookProgress(widget.ebook.id, 1);
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat dokumen: $e';
        _isLoading = false;
      });
    }
  }

  void _editDocument() {
    if (_documentData == null) return;

    // Navigate to editor with existing content
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TextEbookEditorScreen(
              initialText: _quillController.document.toPlainText(),
              initialTitle:
                  _documentData!['title'] as String? ?? widget.ebook.title,
              existingFilePath:
                  widget.ebook.filePath, // Pass existing file path for editing
            ),
      ),
    ).then((_) {
      // Reload document when returning from editor
      _loadDocument();
    });
  }

  Future<void> _shareDocument() async {
    try {
      if (_documentData == null) return;

      final plainText = _quillController.document.toPlainText();
      final title = _documentData!['title'] as String? ?? widget.ebook.title;

      await Share.share('$title\n\n$plainText', subject: title);
    } catch (e) {
      _showErrorSnackBar('Gagal berbagi dokumen: $e');
    }
  }

  void _showDocumentInfo() {
    if (_documentData == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[900] 
            : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _documentData!['title'] as String? ?? 'Dokumen',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(
                      'Dibuat:',
                      _formatDate(_documentData!['createdAt'] as String?),
                    ),
                    _buildInfoRow(
                      'Versi:',
                      _documentData!['version'] as String? ?? '1.0',
                    ),
                    _buildInfoRow('Format:', 'Delta JSON'),
                    _buildInfoRow(
                      'Gambar:',
                      '${(_documentData!['images'] as List?)?.length ?? 0} file',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[800] 
                          : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Dokumen ini menggunakan format Delta JSON yang mempertahankan semua formatting seperti bold, italic, headers, dan lists.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[300] 
                            : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[300] 
                  : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Tidak diketahui';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Tidak diketahui';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.ebook.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: _showDocumentInfo,
            tooltip: 'Info Dokumen',
          ),
          IconButton(
            icon: Icon(
              Icons.share,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: _shareDocument,
            tooltip: 'Bagikan',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Memuat dokumen...'),
                  ],
                ),
              )
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadDocument,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
              : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                ),
                child: GestureDetector(
                  onTap: () {}, // Prevent text selection but allow scrolling
                  child: QuillEditor.basic(
                    controller: _quillController,
                    config: QuillEditorConfig(
                      enableInteractiveSelection: false,
                      embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                    ),
                  ),
                ),
              ),
      floatingActionButton:
          !_isLoading && _errorMessage.isEmpty
              ? FloatingActionButton(
                onPressed: _editDocument,
                backgroundColor: const Color(0xFF2563EB),
                child: const Icon(Icons.edit, color: Colors.white),
              )
              : null,
    );
  }
}
