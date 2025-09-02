import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/data_service.dart';
import '../l10n/app_localizations.dart';

class TextScannerScreen extends StatefulWidget {
  final File imageFile;
  final bool saveImage;

  const TextScannerScreen({
    super.key,
    required this.imageFile,
    this.saveImage = true,
  });

  @override
  State<TextScannerScreen> createState() => _TextScannerScreenState();
}

class _TextScannerScreenState extends State<TextScannerScreen> {
  final DataService _dataService = DataService.instance;
  final TextEditingController _textController = TextEditingController();
  bool _isScanning = false;
  String _scannedText = '';

  @override
  void initState() {
    super.initState();
    _scanTextFromImage();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _scanTextFromImage() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final textRecognizer = TextRecognizer();
      final InputImage inputImage = InputImage.fromFile(widget.imageFile);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText += '${line.text}\n';
        }
      }

      setState(() {
        _scannedText = extractedText.trim();
        _textController.text = _scannedText;
        _isScanning = false;
      });

      await textRecognizer.close();

      // Text scanning completed successfully
    } catch (e) {
      setState(() {
        _isScanning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).textRecognitionFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveToGallery() async {
    if (widget.saveImage && _scannedText.isNotEmpty) {
      try {
        await _dataService.addPhoto(
          imagePath: widget.imageFile.path,
          title: AppLocalizations.of(context).scannedImage,
          description: _scannedText.length > 100 
              ? '${_scannedText.substring(0, 100)}...'
              : _scannedText,
          tags: ['scanned', 'text'],
        );

        // Image saved to gallery successfully

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).imageAndTextSaved),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context).failedToSaveToGallery}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _copyTextToClipboard() async {
    if (_textController.text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _textController.text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).textCopiedToClipboard),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).textScanner),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          if (widget.saveImage)
            IconButton(
              onPressed: _scannedText.isNotEmpty ? _saveToGallery : null,
              icon: const Icon(Icons.save),
              tooltip: AppLocalizations.of(context).saveToGallery,
            ),
        ],
      ),
      body: Column(
        children: [
          // Image preview
          Container(
            height: 250,
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Scanning indicator or results
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.text_fields,
                        color: const Color(0xFF6366F1),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).scanResults,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_isScanning)
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Memindai teks dari gambar...',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).editScannedText,
                          hintStyle: TextStyle(
                            color: Theme.of(context).hintColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF6366F1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                    child: const Text(
                      'Kembali',
                      style: TextStyle(color: Color(0xFF6366F1)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _scannedText.isNotEmpty ? _copyTextToClipboard : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Salin Teks'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
