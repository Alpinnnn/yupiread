import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:docx_to_text/docx_to_text.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'data_service.dart';
import '../screens/text_scanner_screen.dart';
import '../screens/ebook_reader_screen.dart';
import '../l10n/app_localizations.dart';

class SharedFileHandler {
  static const MethodChannel _channel = MethodChannel('Yupiread/shared_files');
  static final DataService _dataService = DataService.instance;
  static BuildContext? _currentContext;
  static final List<Map<String, String>> _pendingFiles = [];

  static void initialize() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static void setContext(BuildContext context) {
    _currentContext = context;
    // Process any pending files
    _processPendingFiles();
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    print('SharedFileHandler: Received method call: ${call.method}');
    switch (call.method) {
      case 'handleSharedFile':
      case 'handleOpenWithFile':
        final String? filePath = call.arguments['filePath'];
        final String? mimeType = call.arguments['mimeType'];
        final String? action = call.arguments['action'] ?? 'SEND';
        
        print('SharedFileHandler: filePath=$filePath, mimeType=$mimeType, action=$action, hasContext=${_currentContext != null}');
        
        if (filePath != null && mimeType != null) {
          if (_currentContext != null) {
            print('SharedFileHandler: Processing ${action == 'VIEW' ? 'open with' : 'shared'} file immediately');
            await _processSharedFile(filePath, mimeType, action == 'VIEW');
          } else {
            print('SharedFileHandler: Storing file for later processing');
            // Store for later processing when context is available
            _pendingFiles.add({
              'filePath': filePath, 
              'mimeType': mimeType,
              'isOpenWith': (action == 'VIEW').toString()
            });
          }
        }
        break;
    }
  }

  static Future<void> _processPendingFiles() async {
    print('SharedFileHandler: Processing ${_pendingFiles.length} pending files');
    if (_currentContext != null && _pendingFiles.isNotEmpty) {
      for (final fileData in _pendingFiles) {
        final isOpenWith = fileData['isOpenWith'] == 'true';
        await _processSharedFile(fileData['filePath']!, fileData['mimeType']!, isOpenWith);
      }
      _pendingFiles.clear();
    }
  }

  static Future<void> _processSharedFile(String filePath, String mimeType, bool isOpenWith) async {
    if (_currentContext == null) return;

    final File file = File(filePath);
    if (!await file.exists()) return;

    if (mimeType.startsWith('image/')) {
      if (isOpenWith) {
        // For "Open With" images, directly scan text instead of showing dialog
        await _scanTextFromImage(_currentContext!, file);
      } else {
        await _handleSharedImage(_currentContext!, file);
      }
    } else if (mimeType == 'application/pdf' || 
               mimeType == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ||
               mimeType == 'application/msword' ||
               mimeType == 'text/plain') {
      await _handleSharedDocument(_currentContext!, file, mimeType, isOpenWith);
    }
  }

  static Future<void> _handleSharedImage(BuildContext context, File imageFile) async {
    final l10n = AppLocalizations.of(context);
    
    // Show dialog with options: Add to Gallery or Scan Text
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sharedImage),
        content: Text(l10n.whatToDoWithImage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'gallery'),
            child: Text(l10n.addToGallery),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'scan'),
            child: Text(l10n.scanText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (result == 'gallery') {
      await _addImageToGallery(context, imageFile);
    } else if (result == 'scan') {
      await _scanTextFromImage(context, imageFile);
    }
  }

  static Future<void> _addImageToGallery(BuildContext context, File imageFile) async {
    try {
      // Copy image to app directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final String newPath = path.join(appDir.path, 'photos', fileName);
      
      // Ensure photos directory exists
      final Directory photosDir = Directory(path.dirname(newPath));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      // Copy file
      final File newFile = await imageFile.copy(newPath);
      
      // Add to gallery with available tags
      final availableTags = _dataService.availableTags;
      final defaultTag = availableTags.contains('shared') ? 'shared' : availableTags.first;
      
      await _dataService.addPhoto(
        imagePath: newFile.path,
        title: 'Shared Image',
        description: 'Image shared from external app',
        tags: [defaultTag],
      );

      // Show success message
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imageAddedToGallery),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToSaveToGallery}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> _scanTextFromImage(BuildContext context, File imageFile) async {
    // Navigate to text scanner screen with the shared image
    // Don't save the image, just scan text from it
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TextScannerScreen(
          imageFile: imageFile,
          saveImage: false, // Don't save the shared image
        ),
      ),
    );
  }

  static Future<void> _handleSharedDocument(BuildContext context, File documentFile, String mimeType, bool isOpenWith) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory ebooksDir = Directory(path.join(appDir.path, 'ebooks'));
      if (!await ebooksDir.exists()) {
        await ebooksDir.create(recursive: true);
      }

      String finalFilePath;
      String fileType = 'pdf';
      String title = path.basenameWithoutExtension(documentFile.path);

      if (mimeType == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ||
          mimeType == 'application/msword') {
        // Convert Word to PDF
        final convertedPdfPath = await _convertWordToPdf(documentFile, ebooksDir);
        finalFilePath = convertedPdfPath;
        fileType = 'pdf';
      } else if (mimeType == 'text/plain') {
        // Copy TXT file
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(documentFile.path)}';
        final String newPath = path.join(ebooksDir.path, fileName);
        final File newFile = await documentFile.copy(newPath);
        finalFilePath = newFile.path;
        fileType = 'txt';
      } else {
        // Copy PDF file
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(documentFile.path)}';
        final String newPath = path.join(ebooksDir.path, fileName);
        final File newFile = await documentFile.copy(newPath);
        finalFilePath = newFile.path;
        fileType = 'pdf';
      }

      // Add to ebook list with available tags
      final availableTags = _dataService.availableTags;
      final defaultTag = availableTags.contains('shared') ? 'shared' : availableTags.first;
      
      final ebook = await _dataService.addEbook(
        title: title,
        filePath: finalFilePath,
        description: 'Document shared from external app',
        tags: [defaultTag],
        fileType: fileType,
      );

      // Navigate to ebook reader
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EbookReaderScreen(
              ebookId: ebook,
            ),
          ),
        );

        // Show success message based on action type
        final l10n = AppLocalizations.of(context);
        final message = isOpenWith 
            ? l10n.documentOpenedWith
            : l10n.documentAddedAndOpened;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToAddDocument}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<String> _convertWordToPdf(File wordFile, Directory ebooksDir) async {
    try {
      // Extract text from Word document
      final bytes = await wordFile.readAsBytes();
      final text = docxToText(bytes);
      
      // Create PDF document
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      
      // Set up text formatting
      final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);
      const double margin = 40;
      final double pageWidth = page.getClientSize().width;
      final double pageHeight = page.getClientSize().height;
      
      // Split text into words for proper wrapping
      final words = text.split(' ');
      double currentY = margin;
      String currentLine = '';
      
      for (final word in words) {
        final testLine = currentLine.isEmpty ? word : '$currentLine $word';
        final textSize = font.measureString(testLine);
        
        if (textSize.width <= pageWidth - (margin * 2)) {
          currentLine = testLine;
        } else {
          // Draw current line and start new line
          if (currentLine.isNotEmpty) {
            page.graphics.drawString(
              currentLine,
              font,
              bounds: Rect.fromLTWH(margin, currentY, pageWidth - (margin * 2), 20),
            );
            currentY += 20;
            
            // Check if we need a new page
            if (currentY > pageHeight - margin) {
              final newPage = document.pages.add();
              newPage.graphics.drawString(
                word,
                font,
                bounds: Rect.fromLTWH(margin, margin, pageWidth - (margin * 2), 20),
              );
              currentY = margin + 20;
            }
          }
          currentLine = word;
        }
      }
      
      // Draw remaining text
      if (currentLine.isNotEmpty) {
        page.graphics.drawString(
          currentLine,
          font,
          bounds: Rect.fromLTWH(margin, currentY, pageWidth - (margin * 2), 20),
        );
      }
      
      // Save PDF to file
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basenameWithoutExtension(wordFile.path)}.pdf';
      final String pdfPath = path.join(ebooksDir.path, fileName);
      final File pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await document.save());
      
      // Dispose document
      document.dispose();
      
      return pdfPath;
    } catch (e) {
      throw Exception('Gagal mengkonversi Word ke PDF: $e');
    }
  }
}
