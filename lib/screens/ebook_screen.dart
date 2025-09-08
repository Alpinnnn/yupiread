import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/ebook_model.dart';
import '../services/data_service.dart';
import 'ebook_reader_screen.dart';
import '../screens/json_ebook_reader_screen.dart';
import '../screens/txt_reader_screen.dart';
import 'text_ebook_editor_screen.dart';
import '../l10n/app_localizations.dart';

// Word document data classes
class WordFormatting {
  bool bold;
  bool italic;
  bool underline;
  double fontSize;
  String fontFamily;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  PdfColor? color;
  PdfColor? backgroundColor;

  WordFormatting({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.fontSize = 12.0,
    this.fontFamily = 'Arial',
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.color,
    this.backgroundColor,
  });
}

class WordElement {
  String type;
  String text;
  WordFormatting formatting;
  bool isHeader;
  int headerLevel;
  String? imageId;

  WordElement({
    required this.type,
    this.text = '',
    required this.formatting,
    this.isHeader = false,
    this.headerLevel = 0,
    this.imageId,
  });
}

class WordDocumentData {
  List<WordElement> elements;
  Map<String, String> relationships;
  Map<String, Uint8List> images;

  WordDocumentData({
    List<WordElement>? elements,
    Map<String, String>? relationships,
    Map<String, Uint8List>? images,
  }) : elements = elements ?? [],
       relationships = relationships ?? {},
       images = images ?? {};
}

class EbookScreen extends StatefulWidget {
  const EbookScreen({super.key});

  @override
  State<EbookScreen> createState() => _EbookScreenState();
}

class _EbookScreenState extends State<EbookScreen> {
  final DataService _dataService = DataService.instance;
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
    Widget readerScreen;

    if (ebook.fileType == 'json_delta') {
      readerScreen = JsonEbookReaderScreen(ebook: ebook);
    } else if (ebook.fileType == 'txt') {
      readerScreen = TxtReaderScreen(ebookId: ebook.id);
    } else {
      readerScreen = EbookReaderScreen(ebookId: ebook.id);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => readerScreen),
    ).then((_) => _updateFilteredEbooks());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        l10n.ebooks,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_filteredEbooks.length} ${l10n.ebooks}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Theme.of(context).cardTheme.shadowColor ??
                                  Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Stack(
                            children: [
                              Icon(
                                Icons.filter_list,
                                color: Theme.of(context).colorScheme.primary,
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
                          onPressed: _showTagFilterDialog,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _showImportBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.2),
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
                        ? _buildEmptyState(context)
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.library_books,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).noEbooksYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.headlineMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).importPdfOrWord,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showImportBottomSheet,
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context).importEbook),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
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
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).cardTheme.shadowColor ??
                  Colors.black.withOpacity(0.04),
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
                      Icons.picture_as_pdf,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${ebook.totalPages} halaman',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ebook.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: ebook.progress,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(
                                  context,
                                ).cardTheme.color?.withOpacity(0.3) ??
                                Colors.grey[800]
                            : Theme.of(context).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                    minHeight: 3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ebook.progressPercentage} selesai',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
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
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: const BorderRadius.only(
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
                Text(
                  'Impor Ebook',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildImportOption(
                        icon: Icons.picture_as_pdf,
                        title: AppLocalizations.of(context).pdfFile,
                        subtitle:
                            AppLocalizations.of(context).importPdfDocument,
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
                        title: AppLocalizations.of(context).wordFile,
                        subtitle:
                            AppLocalizations.of(context).importWordDocument,
                        onTap: () {
                          Navigator.pop(context);
                          _importWordFile();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildImportOption(
                  icon: Icons.edit_note,
                  title: AppLocalizations.of(context).textEbook,
                  subtitle: AppLocalizations.of(context).createNewTextEbook,
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToTextEditor();
                  },
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
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
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
        _showAddEbookDialog(
          fileName.replaceAll('.pdf', ''),
          savedPath,
          'pdf',
          totalPages,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).failedToImportPdf}: ${e.toString()}',
            ),
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
                content: Text(
                  'Saat ini hanya mendukung file .docx. File .doc belum didukung.',
                ),
                backgroundColor: Color(0xFFF59E0B),
              ),
            );
          }
          return;
        }

        // Show loading dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => AlertDialog(
                  content: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 20),
                      Text(AppLocalizations.of(context).convertingWordToPdf),
                    ],
                  ),
                ),
          );
        }

        // Convert Word to PDF
        final pdfPath = await _convertWordToPdf(filePath, fileName);

        // Close loading dialog
        if (mounted) {
          Navigator.pop(context);
        }

        if (pdfPath != null) {
          // Get PDF page count
          int totalPages = await _getPdfPageCount(pdfPath);

          // Show dialog to add metadata
          _showAddEbookDialog(
            fileName.replaceAll('.docx', ''),
            pdfPath,
            'pdf',
            totalPages,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).failedToConvertWord),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).failedToImportWord}: ${e.toString()}',
            ),
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

  // Convert Word document to PDF with advanced formatting and image preservation
  Future<String?> _convertWordToPdf(
    String wordFilePath,
    String fileName,
  ) async {
    try {
      final file = File(wordFilePath);
      if (!await file.exists()) {
        return null;
      }

      // Extract Word document structure
      final bytes = await file.readAsBytes();
      final wordData = await _extractWordData(bytes);

      // Create PDF with enhanced formatting
      final PdfDocument document = PdfDocument();

      // Set up document properties
      document.documentInformation.title = fileName.replaceAll('.docx', '');
      document.documentInformation.creator = 'Yupiread';

      // Create pages with formatted content and images
      await _createAdvancedPdfPages(document, wordData);

      // Save PDF to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final pdfFileName = fileName.replaceAll('.docx', '.pdf');
      final pdfPath = path.join(appDir.path, 'ebooks', pdfFileName);

      // Ensure directory exists
      final pdfDir = Directory(path.dirname(pdfPath));
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      // Save the PDF
      final List<int> pdfBytes = await document.save();
      document.dispose();

      final pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(pdfBytes);

      return pdfPath;
    } catch (e) {
      print('Error converting Word to PDF: $e');
      return null;
    }
  }

  // Extract structured data from Word document
  Future<WordDocumentData> _extractWordData(List<int> bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(Uint8List.fromList(bytes));
      final wordData = WordDocumentData();

      // Extract document.xml for text and formatting
      final documentXml = archive.findFile('word/document.xml');
      if (documentXml != null) {
        // Use UTF-8 decoding to prevent encoding issues
        final xmlContent = utf8.decode(documentXml.content);
        final document = XmlDocument.parse(xmlContent);
        wordData.elements = _parseDocumentElements(document);
      }

      // Extract images from media folder
      final mediaFiles = archive.files.where(
        (file) =>
            file.name.startsWith('word/media/') &&
            (file.name.endsWith('.png') ||
                file.name.endsWith('.jpg') ||
                file.name.endsWith('.jpeg') ||
                file.name.endsWith('.gif')),
      );

      for (final mediaFile in mediaFiles) {
        final imageName = path.basename(mediaFile.name);
        wordData.images[imageName] = mediaFile.content;
      }

      // Extract relationships for image mapping
      final relsFile = archive.findFile('word/_rels/document.xml.rels');
      if (relsFile != null) {
        // Use UTF-8 decoding to prevent encoding issues
        final relsContent = utf8.decode(relsFile.content);
        final relsDoc = XmlDocument.parse(relsContent);
        wordData.relationships = _parseRelationships(relsDoc);
      }

      return wordData;
    } catch (e) {
      print('Error extracting Word data: $e');
      // Fallback to simple text extraction
      final text = docxToText(Uint8List.fromList(bytes));
      return WordDocumentData()
        ..elements = [
          WordElement(
            type: 'paragraph',
            text: text,
            formatting: WordFormatting(),
          ),
        ];
    }
  }

  // Parse document elements with formatting
  List<WordElement> _parseDocumentElements(XmlDocument document) {
    final elements = <WordElement>[];

    final paragraphs = document.findAllElements('w:p');
    for (final paragraph in paragraphs) {
      final element = WordElement(
        type: 'paragraph',
        formatting: WordFormatting(),
      );

      // Parse paragraph properties for header detection
      final paragraphProps = paragraph.findElements('w:pPr').firstOrNull;
      if (paragraphProps != null) {
        final styleElement =
            paragraphProps.findElements('w:pStyle').firstOrNull;
        if (styleElement != null) {
          final styleVal = styleElement.getAttribute('w:val');
          if (styleVal != null &&
              (styleVal.toLowerCase().contains('heading') ||
                  styleVal.toLowerCase().contains('title'))) {
            element.isHeader = true;
            element.headerLevel = _extractHeaderLevel(styleVal);
          }
        }
      }

      final textRuns = paragraph.findAllElements('w:r');

      for (final run in textRuns) {
        final runProps = run.findElements('w:rPr').firstOrNull;
        final formatting = _parseRunFormatting(runProps);

        // Check for images
        final drawings = run.findAllElements('w:drawing');
        if (drawings.isNotEmpty) {
          final imageId = _extractImageId(drawings.first);
          if (imageId != null) {
            elements.add(
              WordElement(
                type: 'image',
                imageId: imageId,
                formatting: formatting,
              ),
            );
            continue;
          }
        }

        // Extract text with proper space handling
        final textElements = run.findAllElements('w:t');
        for (final textElement in textElements) {
          var text = textElement.innerText;
          if (text.isNotEmpty) {
            // Handle XML space preservation
            final spaceAttr = textElement.getAttribute('xml:space');
            if (spaceAttr != 'preserve') {
              // Normalize whitespace but preserve single spaces
              text = text.replaceAll(RegExp(r'\s+'), ' ');
            }
            element.text += text;
            element.formatting = _mergeFormatting(
              element.formatting,
              formatting,
            );
          }
        }

        // Handle tab elements
        final tabElements = run.findAllElements('w:tab');
        for (final _ in tabElements) {
          element.text += '\t';
        }

        // Handle break elements (line breaks)
        final breakElements = run.findAllElements('w:br');
        for (final _ in breakElements) {
          element.text += '\n';
        }
      }

      if (element.text.isNotEmpty || element.imageId != null) {
        elements.add(element);
      }
    }

    return elements;
  }

  // Parse run formatting properties with enhanced support
  WordFormatting _parseRunFormatting(XmlElement? runProps) {
    final formatting = WordFormatting();

    if (runProps != null) {
      formatting.isBold = runProps.findElements('w:b').isNotEmpty;
      formatting.isItalic = runProps.findElements('w:i').isNotEmpty;
      formatting.isUnderline = runProps.findElements('w:u').isNotEmpty;

      // Parse font size
      final sizeElement = runProps.findElements('w:sz').firstOrNull;
      if (sizeElement != null) {
        final sizeValue = sizeElement.getAttribute('w:val');
        if (sizeValue != null) {
          formatting.fontSize =
              double.tryParse(sizeValue) ?? 22.0; // Word uses half-points
          formatting.fontSize = formatting.fontSize / 2; // Convert to points
        }
      }

      // Parse text color
      final colorElement = runProps.findElements('w:color').firstOrNull;
      if (colorElement != null) {
        final colorValue = colorElement.getAttribute('w:val');
        if (colorValue != null && colorValue.length == 6) {
          formatting.color = _parseHexColor(colorValue);
        }
      }

      // Parse highlight/background color
      final highlightElement = runProps.findElements('w:highlight').firstOrNull;
      if (highlightElement != null) {
        final highlightValue = highlightElement.getAttribute('w:val');
        if (highlightValue != null) {
          formatting.backgroundColor = _parseNamedColor(highlightValue);
        }
      }

      // Parse shading (background color)
      final shadingElement = runProps.findElements('w:shd').firstOrNull;
      if (shadingElement != null) {
        final fillValue = shadingElement.getAttribute('w:fill');
        if (fillValue != null && fillValue.length == 6 && fillValue != 'auto') {
          formatting.backgroundColor = _parseHexColor(fillValue);
        }
      }
    }

    return formatting;
  }

  // Parse hex color to PdfColor
  PdfColor _parseHexColor(String hex) {
    try {
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);
      return PdfColor(r, g, b);
    } catch (e) {
      return PdfColor(0, 0, 0); // Default to black
    }
  }

  // Parse named colors (Word highlight colors)
  PdfColor _parseNamedColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'yellow':
        return PdfColor(255, 255, 0);
      case 'green':
        return PdfColor(0, 255, 0);
      case 'cyan':
        return PdfColor(0, 255, 255);
      case 'magenta':
        return PdfColor(255, 0, 255);
      case 'blue':
        return PdfColor(0, 0, 255);
      case 'red':
        return PdfColor(255, 0, 0);
      case 'darkblue':
        return PdfColor(0, 0, 139);
      case 'darkcyan':
        return PdfColor(0, 139, 139);
      case 'darkgreen':
        return PdfColor(0, 100, 0);
      case 'darkmagenta':
        return PdfColor(139, 0, 139);
      case 'darkred':
        return PdfColor(139, 0, 0);
      case 'darkyellow':
        return PdfColor(139, 139, 0);
      case 'darkgray':
        return PdfColor(169, 169, 169);
      case 'lightgray':
        return PdfColor(211, 211, 211);
      default:
        return PdfColor(255, 255, 0); // Default to yellow
    }
  }

  // Extract header level from style name
  int _extractHeaderLevel(String styleName) {
    final match = RegExp(r'(\d+)').firstMatch(styleName);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 1;
    }
    return 1; // Default to level 1
  }

  // Extract image ID from drawing element
  String? _extractImageId(XmlElement drawing) {
    final blips = drawing.findAllElements('a:blip');
    for (final blip in blips) {
      final embed = blip.getAttribute('r:embed');
      if (embed != null) {
        return embed;
      }
    }
    return null;
  }

  // Parse relationships for image mapping
  Map<String, String> _parseRelationships(XmlDocument relsDoc) {
    final relationships = <String, String>{};

    final rels = relsDoc.findAllElements('Relationship');
    for (final rel in rels) {
      final id = rel.getAttribute('Id');
      final target = rel.getAttribute('Target');
      if (id != null && target != null) {
        relationships[id] = target;
      }
    }

    return relationships;
  }

  // Merge formatting properties
  WordFormatting _mergeFormatting(WordFormatting base, WordFormatting overlay) {
    return WordFormatting()
      ..isBold = overlay.isBold || base.isBold
      ..isItalic = overlay.isItalic || base.isItalic
      ..isUnderline = overlay.isUnderline || base.isUnderline
      ..fontSize = overlay.fontSize > 0 ? overlay.fontSize : base.fontSize
      ..color = overlay.color ?? base.color
      ..backgroundColor = overlay.backgroundColor ?? base.backgroundColor;
  }

  // Create advanced PDF pages with formatting and images
  Future<void> _createAdvancedPdfPages(
    PdfDocument document,
    WordDocumentData wordData,
  ) async {
    // Set up fonts and formatting
    final Map<String, PdfFont> fonts = {
      'normal': PdfStandardFont(PdfFontFamily.helvetica, 11),
      'bold': PdfStandardFont(
        PdfFontFamily.helvetica,
        11,
        style: PdfFontStyle.bold,
      ),
      'italic': PdfStandardFont(
        PdfFontFamily.helvetica,
        11,
        style: PdfFontStyle.italic,
      ),
      'boldItalic': PdfStandardFont(
        PdfFontFamily.helvetica,
        11,
        style: PdfFontStyle.bold,
      ),
      'title': PdfStandardFont(
        PdfFontFamily.helvetica,
        16,
        style: PdfFontStyle.bold,
      ),
      'header': PdfStandardFont(
        PdfFontFamily.helvetica,
        14,
        style: PdfFontStyle.bold,
      ),
    };

    // Page layout settings
    const double margin = 50;
    const double paragraphSpacing = 12;

    // Create pages
    PdfPage currentPage = document.pages.add();
    double yPosition = margin;
    final double pageWidth = currentPage.getClientSize().width - (margin * 2);
    final double pageHeight = currentPage.getClientSize().height - margin;

    for (final element in wordData.elements) {
      // Check if we need a new page
      if (yPosition > pageHeight - 100) {
        currentPage = document.pages.add();
        yPosition = margin;
      }

      if (element.type == 'image' && element.imageId != null) {
        // Handle image
        final imagePath = wordData.relationships[element.imageId];
        if (imagePath != null) {
          final imageName = path.basename(imagePath);
          final imageBytes = wordData.images[imageName];

          if (imageBytes != null) {
            try {
              final pdfImage = PdfBitmap(imageBytes);
              final imageWidth = pageWidth * 0.8; // 80% of page width
              final imageHeight =
                  (pdfImage.height * imageWidth) / pdfImage.width;

              // Check if image fits on current page
              if (yPosition + imageHeight > pageHeight - margin) {
                currentPage = document.pages.add();
                yPosition = margin;
              }

              currentPage.graphics.drawImage(
                pdfImage,
                Rect.fromLTWH(
                  margin + (pageWidth - imageWidth) / 2, // Center image
                  yPosition,
                  imageWidth,
                  imageHeight,
                ),
              );

              yPosition += imageHeight + paragraphSpacing;
            } catch (e) {
              print('Error adding image to PDF: $e');
              // Add placeholder text for failed images
              final font = fonts['normal']!;
              final brush = PdfSolidBrush(PdfColor(100, 100, 100));

              currentPage.graphics.drawString(
                '[Gambar tidak dapat dimuat]',
                font,
                brush: brush,
                bounds: Rect.fromLTWH(margin, yPosition, pageWidth, 20),
              );

              yPosition += 20 + paragraphSpacing;
            }
          }
        }
      } else if (element.type == 'paragraph' && element.text.isNotEmpty) {
        // Handle text paragraph with formatting
        final formatting = element.formatting;

        // Determine font based on formatting and header status
        PdfFont font;
        double fontSize =
            formatting.fontSize > 0
                ? formatting.fontSize.clamp(8.0, 24.0)
                : 11.0;

        // Apply header-specific formatting
        if (element.isHeader) {
          switch (element.headerLevel) {
            case 1:
              fontSize = fontSize < 16 ? 18.0 : fontSize * 1.5;
              break;
            case 2:
              fontSize = fontSize < 14 ? 16.0 : fontSize * 1.3;
              break;
            case 3:
              fontSize = fontSize < 12 ? 14.0 : fontSize * 1.2;
              break;
            default:
              fontSize = fontSize < 11 ? 12.0 : fontSize * 1.1;
          }
          // Headers are typically bold
          formatting.isBold = true;
        }

        // Create font with proper style
        if (formatting.isBold && formatting.isItalic) {
          font = PdfStandardFont(
            PdfFontFamily.helvetica,
            fontSize,
            style: PdfFontStyle.bold,
          );
        } else if (formatting.isBold) {
          font = PdfStandardFont(
            PdfFontFamily.helvetica,
            fontSize,
            style: PdfFontStyle.bold,
          );
        } else if (formatting.isItalic) {
          font = PdfStandardFont(
            PdfFontFamily.helvetica,
            fontSize,
            style: PdfFontStyle.italic,
          );
        } else {
          font = PdfStandardFont(PdfFontFamily.helvetica, fontSize);
        }

        // Determine text color
        final textBrush = PdfSolidBrush(formatting.color ?? PdfColor(0, 0, 0));

        // Handle background color if present
        if (formatting.backgroundColor != null) {
          // Draw background rectangle first
          final backgroundBrush = PdfSolidBrush(formatting.backgroundColor!);

          // Measure text to get background size
          final textSize = font.measureString(element.text);
          final backgroundRect = Rect.fromLTWH(
            margin - 2,
            yPosition - 2,
            textSize.width + 4,
            textSize.height + 4,
          );

          currentPage.graphics.drawRectangle(
            brush: backgroundBrush,
            bounds: backgroundRect,
          );
        }

        // Create text element with formatting
        final textElement = PdfTextElement(
          text: element.text,
          font: font,
          brush: textBrush,
        );

        // Draw text with pagination
        final result =
            textElement.draw(
              page: currentPage,
              bounds: Rect.fromLTWH(margin, yPosition, pageWidth, 0),
              format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
            )!;

        // Add extra spacing for headers
        final extraSpacing = element.isHeader ? paragraphSpacing * 1.5 : 0;
        yPosition = result.bounds.bottom + paragraphSpacing + extraSpacing;

        // Update current page if text flowed to next page
        if (result.page != currentPage) {
          currentPage = result.page;
          yPosition = result.bounds.bottom + paragraphSpacing + extraSpacing;
        }
      }
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
                                  selectedColor: Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF3B82F6).withOpacity(0.3)
                                      : const Color(0xFF2563EB).withOpacity(0.2),
                                  checkmarkColor: Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF60A5FA)
                                      : const Color(0xFF2563EB),
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
                            fileType: fileType,
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

  void _navigateToTextEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TextEbookEditorScreen()),
    ).then((_) => _updateFilteredEbooks());
  }

  void _showTagFilterDialog() {
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
                                  selectedColor: Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF3B82F6).withOpacity(0.3)
                                      : const Color(0xFF2563EB).withOpacity(0.2),
                                  checkmarkColor: Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF60A5FA)
                                      : const Color(0xFF2563EB),
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
}
