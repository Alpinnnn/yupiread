import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/data_service.dart';
import '../services/text_recognition_service.dart';
import '../l10n/app_localizations.dart';

class TextToEbookEditorScreen extends StatefulWidget {
  final String? initialText;
  final List<String>? imagePaths;
  final String? existingEbookId; // For editing existing ebooks

  const TextToEbookEditorScreen({
    super.key,
    this.initialText,
    this.imagePaths,
    this.existingEbookId,
  });

  @override
  State<TextToEbookEditorScreen> createState() => _TextToEbookEditorScreenState();
}

class _TextToEbookEditorScreenState extends State<TextToEbookEditorScreen> {
  final DataService _dataService = DataService.instance;
  final TextRecognitionService _textRecognitionService = TextRecognitionService.instance;
  
  late TextEditingController _titleController;
  late TextEditingController _textController;
  late TextEditingController _descriptionController;
  
  List<String> _selectedTags = [];
  bool _isLoading = false;
  bool _isExtracting = false;
  String _extractionStatus = '';
  List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _textController = TextEditingController(text: widget.initialText ?? '');
    _descriptionController = TextEditingController();
    _imagePaths = widget.imagePaths ?? [];
    
    if (widget.existingEbookId != null) {
      _loadExistingEbook();
    } else {
      // Set default title after first build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _titleController.text.isEmpty) {
          _titleController.text = AppLocalizations.of(context).ebookFromText;
        }
      });
    }
    
    // Extract text from images if provided
    if (_imagePaths.isNotEmpty && widget.initialText == null) {
      _extractTextFromImages();
    }
  }

  void _loadExistingEbook() {
    final ebook = _dataService.getEbook(widget.existingEbookId!);
    if (ebook != null) {
      _titleController.text = ebook.title;
      _descriptionController.text = ebook.description;
      _selectedTags = List.from(ebook.tags);
      // Note: For existing ebooks, we can't load the original text content
      // as PDFs don't store editable text. This would be for new text-based ebooks.
    }
  }

  Future<void> _extractTextFromImages() async {
    if (_imagePaths.isEmpty) return;
    
    setState(() {
      _isExtracting = true;
      _extractionStatus = 'Mengekstrak teks dari ${_imagePaths.length} gambar...';
    });

    try {
      String extractedText;
      if (_imagePaths.length == 1) {
        extractedText = await _textRecognitionService.extractTextFromImage(_imagePaths.first);
      } else {
        extractedText = await _textRecognitionService.extractTextFromMultipleImages(_imagePaths);
      }

      final cleanedText = _textRecognitionService.cleanExtractedText(extractedText);
      
      setState(() {
        _textController.text = cleanedText;
        _isExtracting = false;
        _extractionStatus = '';
      });

      if (cleanedText.isEmpty) {
        _showMessage(AppLocalizations.of(context).noTextExtracted, isError: true);
      } else {
        _showMessage(AppLocalizations.of(context).textExtractedSuccess);
      }
    } catch (e) {
      setState(() {
        _isExtracting = false;
        _extractionStatus = '';
      });
      _showMessage('${AppLocalizations.of(context).textExtractionFailed}${e.toString()}', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  void _showTagSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Tag'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _dataService.availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        checkmarkColor: Theme.of(context).colorScheme.primary,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  Future<String> _convertTextToPdf(String text, String title) async {
    try {
      // Create PDF document
      final PdfDocument document = PdfDocument();
      
      // Add page
      final PdfPage page = document.pages.add();
      PdfGraphics graphics = page.graphics;
      
      // Set font
      final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);
      final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
      
      // Page dimensions
      const double margin = 40;
      final double pageWidth = page.getClientSize().width;
      final double pageHeight = page.getClientSize().height;
      double yPosition = margin;
      
      // Draw title
      graphics.drawString(
        title,
        titleFont,
        bounds: Rect.fromLTWH(margin, yPosition, pageWidth - 2 * margin, 30),
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      );
      yPosition += 50;
      
      // Split text into lines that fit the page width
      final List<String> lines = _splitTextIntoLines(text, font, pageWidth - 2 * margin);
      const double lineHeight = 18;
      
      for (String line in lines) {
        // Check if we need a new page
        if (yPosition + lineHeight > pageHeight - margin) {
          final PdfPage newPage = document.pages.add();
          final PdfGraphics newGraphics = newPage.graphics;
          graphics = newGraphics;
          yPosition = margin;
        }
        
        // Draw line
        graphics.drawString(
          line,
          font,
          bounds: Rect.fromLTWH(margin, yPosition, pageWidth - 2 * margin, lineHeight),
          brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        );
        yPosition += lineHeight;
      }
      
      // Save PDF directly to ebooks directory
      final appDir = await getApplicationDocumentsDirectory();
      final ebookDir = Directory('${appDir.path}/ebooks');
      if (!await ebookDir.exists()) {
        await ebookDir.create(recursive: true);
      }
      
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_text_ebook.pdf';
      final String pdfPath = '${ebookDir.path}/$fileName';
      
      final File file = File(pdfPath);
      await file.writeAsBytes(await document.save());
      document.dispose();
      
      return pdfPath;
    } catch (e) {
      throw Exception('Failed to convert text to PDF: $e');
    }
  }

  List<String> _splitTextIntoLines(String text, PdfFont font, double maxWidth) {
    final List<String> lines = [];
    final List<String> paragraphs = text.split('\n');
    
    for (String paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) {
        lines.add('');
        continue;
      }
      
      final List<String> words = paragraph.split(' ');
      String currentLine = '';
      
      for (String word in words) {
        final String testLine = currentLine.isEmpty ? word : '$currentLine $word';
        final Size textSize = font.measureString(testLine);
        
        if (textSize.width <= maxWidth) {
          currentLine = testLine;
        } else {
          if (currentLine.isNotEmpty) {
            lines.add(currentLine);
            currentLine = word;
          } else {
            // Word is too long, break it
            lines.add(word);
            currentLine = '';
          }
        }
      }
      
      if (currentLine.isNotEmpty) {
        lines.add(currentLine);
      }
    }
    
    return lines;
  }

  Future<void> _saveEbook() async {
    if (_titleController.text.trim().isEmpty) {
      _showMessage(AppLocalizations.of(context).ebookTitleRequired, isError: true);
      return;
    }
    
    if (_textController.text.trim().isEmpty) {
      _showMessage(AppLocalizations.of(context).textContentRequired, isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert text to PDF
      final String pdfPath = await _convertTextToPdf(
        _textController.text.trim(),
        _titleController.text.trim(),
      );

      // Save ebook to data service
      await _dataService.addEbook(
        title: _titleController.text.trim(),
        filePath: pdfPath,
        tags: _selectedTags,
        description: _descriptionController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      _showMessage(AppLocalizations.of(context).ebookSavedSuccess);
      
      // Navigate back to ebook screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('${AppLocalizations.of(context).ebookSaveFailed}${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.existingEbookId != null ? AppLocalizations.of(context).editEbook : AppLocalizations.of(context).createEbookFromText,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontSize: 18,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!_isLoading && !_isExtracting)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveEbook,
              tooltip: AppLocalizations.of(context).saveEbook,
            ),
        ],
      ),
      body: _isExtracting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _extractionStatus,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).ebookTitle,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  
                  // Description field
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).descriptionOptional,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                    maxLength: 200,
                  ),
                  const SizedBox(height: 16),
                  
                  // Tags section
                  Row(
                    children: [
                      const Icon(Icons.local_offer, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tag (${_selectedTags.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _showTagSelectionDialog,
                        child: Text(AppLocalizations.of(context).selectTags),
                      ),
                    ],
                  ),
                  if (_selectedTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _selectedTags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              _selectedTags.remove(tag);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  
                  // Text content section
                  Row(
                    children: [
                      const Icon(Icons.text_fields, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).textContent,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${_textController.text.length} karakter',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Text editor
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).enterEditTextHere,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      maxLines: null,
                      minLines: 10,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.cancel),
                          label: Text(AppLocalizations.of(context).cancel),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveEbook,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isLoading ? AppLocalizations.of(context).saving : AppLocalizations.of(context).saveEbook),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
