import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import '../services/text_recognition_service.dart';
import '../services/data_service.dart';
import '../l10n/app_localizations.dart';
import 'document_scanner_screen.dart';

class TextEbookEditorScreen extends StatefulWidget {
  final String? initialText;
  final String? initialTitle;
  final String? existingFilePath; // For editing existing documents

  const TextEbookEditorScreen({
    super.key,
    this.initialText,
    this.initialTitle,
    this.existingFilePath,
  });

  @override
  State<TextEbookEditorScreen> createState() => _TextEbookEditorScreenState();
}

class _TextEbookEditorScreenState extends State<TextEbookEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  late QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  
  final TextRecognitionService _textRecognitionService = TextRecognitionService.instance;
  final DataService _dataService = DataService.instance;

  bool _isSaving = false;
  bool _isToolbarVisible = true;
  List<String> _insertedImages = [];
  bool _isEditingExisting = false;
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? 'Ebook Baru';
    _isEditingExisting = widget.existingFilePath != null;
    
    // Initialize quill controller with initial text if provided
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      final document = Document()..insert(0, widget.initialText!);
      _quillController = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      _quillController = QuillController.basic();
    }
    
    // Auto-hide toolbar when typing
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _focusNode.hasFocus) {
            setState(() {
              _isToolbarVisible = false;
            });
          }
        });
      }
    });

    // Setup formatting preservation
    _setupFormattingPreservation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Load existing document and tags after dependencies are available
    if (_isEditingExisting) {
      _loadExistingDocument();
      _loadExistingTags();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Setup formatting preservation for line breaks
  void _setupFormattingPreservation() {
    // This is a workaround for the flutter_quill formatting issue
    // We'll use a different approach with custom key handling
  }

  // Load existing document for editing
  Future<void> _loadExistingDocument() async {
    if (widget.existingFilePath == null) return;
    
    try {
      final file = File(widget.existingFilePath!);
      if (await file.exists()) {
        final content = await file.readAsString();
        
        // Try to parse as JSON first (for Delta format)
        try {
          final jsonData = jsonDecode(content);
          if (jsonData is Map<String, dynamic> && jsonData.containsKey('delta')) {
            // Load from Delta format
            final deltaList = jsonData['delta'] as List<dynamic>;
            final document = Document.fromJson(deltaList);
            _quillController = QuillController(
              document: document,
              selection: const TextSelection.collapsed(offset: 0),
            );
            
            // Load title if available
            if (jsonData.containsKey('title')) {
              _titleController.text = jsonData['title'] as String;
            }
          } else {
            // Fallback to plain text
            final document = Document()..insert(0, content);
            _quillController = QuillController(
              document: document,
              selection: const TextSelection.collapsed(offset: 0),
            );
          }
        } catch (jsonError) {
          // If JSON parsing fails, treat as plain text
          final document = Document()..insert(0, content);
          _quillController = QuillController(
            document: document,
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
        
        setState(() {});
      }
    } catch (e) {
      print('Error loading existing document: $e');
    }
  }

  // Load existing tags when editing
  void _loadExistingTags() {
    if (widget.existingFilePath == null) return;
    
    try {
      // Get ebook by file path to load existing tags
      final ebooks = _dataService.ebooks;
      final ebook = ebooks.firstWhere(
        (e) => e.filePath == widget.existingFilePath,
        orElse: () => throw Exception('Ebook not found'),
      );
      
      setState(() {
        _selectedTags = List.from(ebook.tags);
      });
    } catch (e) {
      print('Error loading existing tags: $e');
    }
  }
  
  // Show tags selection dialog
  void _showTagsDialog() {
    List<String> tempSelectedTags = List.from(_selectedTags);
    final allTags = _dataService.availableTags;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                AppLocalizations.of(context).selectTags,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: allTags.map((tag) {
                      final isSelected = tempSelectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        selectedColor: const Color(0xFF2563EB).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF2563EB),
                        backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              tempSelectedTags.add(tag);
                            } else {
                              tempSelectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context).cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedTags = tempSelectedTags;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppLocalizations.of(context).save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Menyimpan dokumen dengan format Delta JSON (mempertahankan formatting)
  Future<void> _saveDeltaDocument() async {
    try {
      String filePath;
      
      if (_isEditingExisting && widget.existingFilePath != null) {
        // Update existing file
        filePath = widget.existingFilePath!;
      } else {
        // Create new file
        final directory = await getApplicationDocumentsDirectory();
        final fileName = '${_titleController.text.trim().replaceAll(' ', '_')}_delta_${DateTime.now().millisecondsSinceEpoch}.json';
        filePath = '${directory.path}/$fileName';
      }
      
      // Ekstrak delta dengan semua formatting
      final delta = _quillController.document.toDelta();
      
      // Buat struktur data lengkap
      final documentData = {
        'title': _titleController.text.trim(),
        'delta': delta.toJson(),
        'images': _insertedImages,
        'createdAt': _isEditingExisting ? 
          (await _getOriginalCreatedDate(filePath)) : 
          DateTime.now().toIso8601String(),
        'lastModified': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      
      // Simpan sebagai JSON
      final jsonString = jsonEncode(documentData);
      await File(filePath).writeAsString(jsonString);
      
      _showSuccessSnackBar(_isEditingExisting ? 
        'Dokumen berhasil diperbarui' : 
        'Dokumen berhasil disimpan');
      
      // Update data service
      if (_isEditingExisting) {
        // Update existing ebook with title and tags
        final ebooks = _dataService.ebooks;
        final ebook = ebooks.firstWhere(
          (e) => e.filePath == filePath,
          orElse: () => throw Exception('Ebook not found'),
        );
        
        _dataService.updateEbook(
          id: ebook.id,
          title: _titleController.text.trim(),
          tags: _selectedTags,
        );
      } else {
        // Save as new ebook
        _dataService.addEbook(
          title: _titleController.text.trim(),
          description: '', // We can add description field later if needed
          filePath: filePath,
          tags: _selectedTags,
          fileType: 'json_delta',
        );
      }
      
    } catch (e) {
      _showErrorSnackBar('Gagal menyimpan dokumen: $e');
    }
  }
  
  Future<String> _getOriginalCreatedDate(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        return data['createdAt'] as String? ?? DateTime.now().toIso8601String();
      }
    } catch (e) {
      // Ignore error, return current time
    }
    return DateTime.now().toIso8601String();
  }

  void _toggleToolbar() {
    setState(() {
      _isToolbarVisible = !_isToolbarVisible;
    });
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }






  Future<void> _scanDocumentFromCamera() async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentScannerScreen(
            useGallery: false,
            onDocumentsScanned: _processScannedDocuments,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Gagal membuka scanner: $e');
    }
  }

  Future<void> _scanDocumentFromGallery() async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentScannerScreen(
            useGallery: true,
            onDocumentsScanned: _processScannedDocuments,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Gagal membuka scanner: $e');
    }
  }

  Future<void> _processScannedDocuments(List<String> scannedPaths) async {
    try {
      for (String imagePath in scannedPaths) {
        // Insert scanned document as image in the editor
        final index = _quillController.selection.baseOffset;
        _quillController.document.insert(index, BlockEmbed.image(imagePath));
        _quillController.updateSelection(
          TextSelection.collapsed(offset: index + 1),
          ChangeSource.local,
        );
        
        // Add to inserted images list
        _insertedImages.add(imagePath);
        
        // Optionally extract text from scanned document
        try {
          final extractedText = await _textRecognitionService.extractTextFromImage(imagePath);
          if (extractedText.isNotEmpty) {
            // Insert extracted text after the image
            final textIndex = _quillController.selection.baseOffset;
            _quillController.document.insert(textIndex, '\n$extractedText\n');
            _quillController.updateSelection(
              TextSelection.collapsed(offset: textIndex + extractedText.length + 2),
              ChangeSource.local,
            );
          }
        } catch (textError) {
          // Continue even if text extraction fails
        }
      }
      
      _showSuccessSnackBar('${scannedPaths.length} dokumen berhasil di-scan dan ditambahkan');
    } catch (e) {
      _showErrorSnackBar('Gagal memproses dokumen yang di-scan: $e');
    }
  }

  void _showDocumentScanDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).scanDocument,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomSheetOption(
                  icon: Icons.camera_alt,
                  label: AppLocalizations.of(context).scanFromCamera,
                  onTap: () {
                    Navigator.pop(context);
                    _scanDocumentFromCamera();
                  },
                ),
                _buildBottomSheetOption(
                  icon: Icons.photo_library,
                  label: AppLocalizations.of(context).scanFromGallery,
                  onTap: () {
                    Navigator.pop(context);
                    _scanDocumentFromGallery();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }


  Widget _buildDialogOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 36,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 40,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditingExisting ? 'Edit Ebook' : 'Buat Ebook Baru',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isToolbarVisible ? Icons.keyboard_hide : Icons.keyboard,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: _toggleToolbar,
          ),
          IconButton(
            icon: Icon(Icons.save, color: isDark ? Colors.white : Colors.black87),
            onPressed: _isSaving ? null : () async {
              setState(() => _isSaving = true);
              await _saveDeltaDocument();
              setState(() => _isSaving = false);
              
              // Navigate back after saving
              if (!_isEditingExisting) {
                Navigator.pop(context);
              }
            },
            tooltip: _isEditingExisting ? 'Perbarui Dokumen' : 'Simpan Dokumen',
          ),
        ],
      ),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: Column(
        children: [
          // Title input with tags icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[50],
            ),
            child: Row(
              children: [
                // Tags icon button
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    onPressed: _showTagsDialog,
                    icon: Icon(
                      Icons.local_offer,
                      color: _selectedTags.isNotEmpty 
                          ? const Color(0xFF2563EB)
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      size: 24,
                    ),
                    tooltip: 'Edit Tags',
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                      side: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                // Title input field
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Judul Ebook',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Colors.blue[400]! : const Color(0xFF2563EB),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.white,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tags display
          if (_selectedTags.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[50],
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedTags.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                    deleteIcon: Icon(
                      Icons.close,
                      size: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onDeleted: () {
                      setState(() {
                        _selectedTags.remove(tag);
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          
          // QuillToolbar
          if (_isToolbarVisible)
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: QuillSimpleToolbar(
                controller: _quillController,
                config: QuillSimpleToolbarConfig(
                  embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                ),
              ),
            ),
          
          // Editor
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
              ),
              child: QuillEditor(
                controller: _quillController,
                focusNode: _focusNode,
                scrollController: ScrollController(),
                config: QuillEditorConfig(
                  embedBuilders: [
                    ...FlutterQuillEmbeds.editorBuilders(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showDocumentScanDialog,
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.document_scanner, color: Colors.white),
        tooltip: AppLocalizations.of(context).scanDocument,
      ),
    );
  }
}
