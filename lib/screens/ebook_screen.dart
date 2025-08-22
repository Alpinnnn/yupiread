import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';
import '../models/ebook_model.dart';
import '../services/data_service.dart';
import 'ebook_reader_screen.dart';
import 'word_reader_screen.dart';

class EbookScreen extends StatefulWidget {
  const EbookScreen({super.key});

  @override
  State<EbookScreen> createState() => _EbookScreenState();
}

class _EbookScreenState extends State<EbookScreen> {
  final DataService _dataService = DataService();
  List<EbookModel> _ebooks = [];
  List<String> _selectedTags = [];
  List<EbookModel> _filteredEbooks = [];

  @override
  void initState() {
    super.initState();
    _updateFilteredEbooks();
  }

  void _updateFilteredEbooks() {
    setState(() {
      _ebooks = _dataService.ebooks;
      _filteredEbooks = _dataService.getFilteredEbooks(_selectedTags);
    });
  }

  void _openEbook(EbookModel ebook) {
    if (ebook.fileType == 'word') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WordReaderScreen(ebookId: ebook.id),
        ),
      ).then((_) => _updateFilteredEbooks());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EbookReaderScreen(ebookId: ebook.id),
        ),
      ).then((_) => _updateFilteredEbooks());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ebook',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_filteredEbooks.length} ebook tersedia',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Stack(
                            children: [
                              const Icon(
                                Icons.filter_list,
                                color: Color(0xFF2563EB),
                              ),
                              if (_selectedTags.isNotEmpty)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 12,
                                      minHeight: 12,
                                    ),
                                    child: Text(
                                      '${_selectedTags.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onPressed: _showFilterDialog,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _showImportBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child:
                    _filteredEbooks.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                          itemCount: _filteredEbooks.length,
                          itemBuilder: (context, index) {
                            return _buildEbookCard(
                              context,
                              _filteredEbooks[index],
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.menu_book,
              size: 48,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum ada ebook',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Impor file PDF atau Word untuk mulai membaca',
            style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showImportBottomSheet,
            icon: const Icon(Icons.add),
            label: const Text('Impor Ebook'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEbookCard(BuildContext context, EbookModel ebook) {
    final categoryColors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF06B6D4),
    ];

    final colorIndex = ebook.id.hashCode % categoryColors.length;
    final categoryColor = categoryColors[colorIndex.abs()];

    return GestureDetector(
      onTap: () {
        _openEbook(ebook);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [categoryColor, categoryColor.withOpacity(0.7)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Icon(
                      Icons.menu_book,
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ebook.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ebook.totalPages} halaman',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (ebook.tags.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            ebook.tags.first,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: categoryColor,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ebook.timeAgo,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: ebook.progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                    minHeight: 3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ebook.progressPercentage} selesai',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
              onSelected: (value) {
                switch (value) {
                  case 'read':
                    _openEbook(ebook);
                    break;
                  case 'edit':
                    _showEditEbookDialog(ebook);
                    break;
                  case 'delete':
                    _deleteEbook(ebook);
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'read',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow, size: 16),
                          SizedBox(width: 8),
                          Text('Baca'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImportBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
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
                const Text(
                  'Impor Ebook',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildImportOption(
                        icon: Icons.picture_as_pdf,
                        title: 'File PDF',
                        subtitle: 'Impor dokumen PDF',
                        onTap: () {
                          Navigator.pop(context);
                          _importPdfFile();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildImportOption(
                        icon: Icons.description,
                        title: 'File Word',
                        subtitle: 'Impor dokumen Word',
                        onTap: () {
                          Navigator.pop(context);
                          _importWordFile();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildImportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF2563EB)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        // Save file to app directory
        final savedPath = await _dataService.saveEbookFile(filePath);

        // Get PDF page count
        int totalPages = await _getPdfPageCount(savedPath);

        // Show dialog to add metadata
        _showAddEbookDialog(fileName.replaceAll('.pdf', ''), savedPath, 'pdf', totalPages);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengimpor file PDF: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _importWordFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx'], // Only support .docx for now
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        // Check if it's actually a .docx file
        if (!fileName.toLowerCase().endsWith('.docx')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saat ini hanya mendukung file .docx. File .doc belum didukung.'),
                backgroundColor: Color(0xFFF59E0B),
              ),
            );
          }
          return;
        }

        // Save file to app directory
        final savedPath = await _dataService.saveEbookFile(filePath);

        // Get Word page count (estimate based on text length)
        int totalPages = await _getWordPageCount(savedPath);

        // Show dialog to add metadata
        _showAddEbookDialog(fileName.replaceAll('.docx', ''), savedPath, 'word', totalPages);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengimpor file Word: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  // Get PDF page count using Syncfusion PDF viewer
  Future<int> _getPdfPageCount(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return 1; // Default fallback
      }
      
      // Use Syncfusion to get page count
      final document = PdfDocument(inputBytes: await file.readAsBytes());
      final pageCount = document.pages.count;
      document.dispose();
      
      return pageCount > 0 ? pageCount : 1;
    } catch (e) {
      // Fallback to 1 if unable to read PDF
      return 1;
    }
  }

  // Get Word page count by estimating from text length
  Future<int> _getWordPageCount(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('Word file does not exist for page count: $filePath');
        return 1; // Default fallback
      }
      
      // Extract text from Word document
      final bytes = await file.readAsBytes();
      print('Word file size for page count: ${bytes.length} bytes');
      
      String text = docxToText(bytes);
      print('Raw extracted text length: ${text.length} characters');
      
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
      
      print('Cleaned text length for page count: ${text.length} characters');
      
      // Estimate pages based on text length
      // Assuming ~500 words per page (average)
      final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
      final estimatedPages = (words / 500).ceil();
      
      print('Word count: $words, Estimated pages: $estimatedPages');
      
      return estimatedPages > 0 ? estimatedPages : 1;
    } catch (e) {
      print('Error getting Word page count: $e');
      // Fallback to 1 if unable to read Word document
      return 1;
    }
  }

  void _showAddEbookDialog(
    String defaultTitle,
    String filePath,
    String fileType,
    int totalPages,
  ) {
    final TextEditingController titleController = TextEditingController(
      text: defaultTitle,
    );
    final TextEditingController descriptionController = TextEditingController();
    List<String> selectedTags = [];

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
                    'Tambah Ebook',
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
                            labelText: 'Deskripsi (Opsional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Pilih Tag (Opsional):',
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
                      onPressed: () {
                        Navigator.pop(context);
                        // Delete the saved file if user cancels
                        try {
                          File(filePath).delete();
                        } catch (e) {
                          // Ignore deletion errors
                        }
                      },
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final ebookTitle = titleController.text.trim();
                        final ebookDescription =
                            descriptionController.text.trim();

                        if (ebookTitle.isNotEmpty) {
                          _dataService.addEbook(
                            title: ebookTitle,
                            filePath: filePath,
                            tags: selectedTags,
                            description: ebookDescription,
                            totalPages: totalPages,
                          );
                          _updateFilteredEbooks();
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Ebook "$ebookTitle" berhasil ditambahkan',
                              ),
                              backgroundColor: const Color(0xFF10B981),
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

  void _showEditEbookDialog(EbookModel ebook) {
    final TextEditingController titleController = TextEditingController(
      text: ebook.title,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: ebook.description,
    );
    List<String> selectedTags = List.from(ebook.tags);

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
                            labelText: 'Deskripsi (Opsional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Pilih Tag (Opsional):',
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
                        final ebookTitle = titleController.text.trim();
                        final ebookDescription =
                            descriptionController.text.trim();

                        if (ebookTitle.isNotEmpty) {
                          _dataService.updateEbook(
                            id: ebook.id,
                            title: ebookTitle,
                            tags: selectedTags,
                            description: ebookDescription,
                          );
                          _updateFilteredEbooks();
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Ebook "$ebookTitle" berhasil diperbarui',
                              ),
                              backgroundColor: const Color(0xFF10B981),
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

  void _showFilterDialog() {
    final usedTags = _dataService.getUsedEbookTags();
    if (usedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada tag yang tersedia untuk filter'),
        ),
      );
      return;
    }

    List<String> tempSelectedTags = List.from(_selectedTags);

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
                    'Filter Berdasarkan Tag',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children:
                              usedTags.map((tag) {
                                final isSelected = tempSelectedTags.contains(
                                  tag,
                                );
                                return FilterChip(
                                  label: Text(tag),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setDialogState(() {
                                      if (selected) {
                                        tempSelectedTags.add(tag);
                                      } else {
                                        tempSelectedTags.remove(tag);
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
                      onPressed: () {
                        setDialogState(() {
                          tempSelectedTags.clear();
                        });
                      },
                      child: const Text('Reset'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTags = tempSelectedTags;
                        });
                        _updateFilteredEbooks();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Terapkan'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _deleteEbook(EbookModel ebook) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Hapus Ebook'),
            content: Text(
              'Apakah Anda yakin ingin menghapus "${ebook.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  _dataService.deleteEbook(ebook.id);
                  _updateFilteredEbooks();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ebook "${ebook.title}" berhasil dihapus'),
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
