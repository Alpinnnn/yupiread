import 'dart:io';
import 'dart:ui' as ui;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

class TextRecognitionService {
  static final TextRecognitionService _instance = TextRecognitionService._internal();
  factory TextRecognitionService() => _instance;
  static TextRecognitionService get instance => _instance;
  TextRecognitionService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Check if image meets minimum size requirements and resize if needed
  Future<String> _preprocessImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      // Check if image meets minimum requirements (321x321)
      if (image.width >= 321 && image.height >= 321) {
        return imagePath; // Image is already large enough
      }
      
      // Calculate scale factor to meet minimum requirements
      final scaleX = 321.0 / image.width;
      final scaleY = 321.0 / image.height;
      final scale = scaleX > scaleY ? scaleX : scaleY;
      
      final newWidth = (image.width * scale).round();
      final newHeight = (image.height * scale).round();
      
      // Create a new image with the required size
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      
      // Draw the original image scaled up
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        ui.Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
        ui.Paint(),
      );
      
      final picture = recorder.endRecording();
      final resizedImage = await picture.toImage(newWidth, newHeight);
      final resizedBytes = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      
      // Save the resized image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_resized_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(resizedBytes!.buffer.asUint8List());
      
      return tempFile.path;
    } catch (e) {
      // If preprocessing fails, return original path and let ML Kit handle it
      return imagePath;
    }
  }

  /// Extract text from image file
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      // Preprocess image to ensure minimum size requirements
      final processedImagePath = await _preprocessImage(imagePath);
      
      final inputImage = InputImage.fromFilePath(processedImagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Clean up temporary file if it was created
      if (processedImagePath != imagePath) {
        try {
          await File(processedImagePath).delete();
        } catch (_) {
          // Ignore cleanup errors
        }
      }
      
      // Combine all text blocks into a single string
      StringBuffer extractedText = StringBuffer();
      
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText.writeln(line.text);
        }
        // Add extra line break between blocks for better formatting
        extractedText.writeln();
      }
      
      return extractedText.toString().trim();
    } catch (e) {
      throw Exception('Failed to extract text from image: $e');
    }
  }

  /// Extract text from multiple images and combine them
  Future<String> extractTextFromMultipleImages(List<String> imagePaths) async {
    try {
      StringBuffer combinedText = StringBuffer();
      
      for (int i = 0; i < imagePaths.length; i++) {
        final imagePath = imagePaths[i];
        final extractedText = await extractTextFromImage(imagePath);
        
        if (extractedText.isNotEmpty) {
          // Add page separator for multiple images
          if (i > 0) {
            combinedText.writeln('\n--- Halaman ${i + 1} ---\n');
          }
          combinedText.writeln(extractedText);
        }
      }
      
      return combinedText.toString().trim();
    } catch (e) {
      throw Exception('Failed to extract text from multiple images: $e');
    }
  }

  /// Clean and format extracted text
  String cleanExtractedText(String rawText) {
    if (rawText.isEmpty) return rawText;
    
    // Remove excessive whitespace and normalize line breaks
    String cleaned = rawText
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n') // Replace multiple line breaks with double
        .replaceAll(RegExp(r'[ \t]+'), ' ') // Replace multiple spaces/tabs with single space
        .trim();
    
    return cleaned;
  }

  /// Get text recognition confidence/quality info
  Future<TextRecognitionResult> extractTextWithDetails(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      StringBuffer extractedText = StringBuffer();
      List<TextBlockInfo> blockInfos = [];
      int totalElements = 0;
      
      for (TextBlock block in recognizedText.blocks) {
        List<String> blockLines = [];
        
        for (TextLine line in block.lines) {
          extractedText.writeln(line.text);
          blockLines.add(line.text);
          totalElements += line.elements.length;
        }
        
        blockInfos.add(TextBlockInfo(
          text: block.text,
          lines: blockLines,
          boundingBox: block.boundingBox,
        ));
        
        extractedText.writeln();
      }
      
      return TextRecognitionResult(
        text: extractedText.toString().trim(),
        blocks: blockInfos,
        totalElements: totalElements,
        confidence: _calculateConfidence(recognizedText),
      );
    } catch (e) {
      throw Exception('Failed to extract text with details: $e');
    }
  }

  double _calculateConfidence(RecognizedText recognizedText) {
    // Simple confidence calculation based on number of recognized elements
    int totalElements = 0;
    int validElements = 0;
    
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement element in line.elements) {
          totalElements++;
          // Consider elements with more than 1 character as valid
          if (element.text.length > 1) {
            validElements++;
          }
        }
      }
    }
    
    return totalElements > 0 ? (validElements / totalElements) : 0.0;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class TextRecognitionResult {
  final String text;
  final List<TextBlockInfo> blocks;
  final int totalElements;
  final double confidence;

  TextRecognitionResult({
    required this.text,
    required this.blocks,
    required this.totalElements,
    required this.confidence,
  });
}

class TextBlockInfo {
  final String text;
  final List<String> lines;
  final ui.Rect boundingBox;

  TextBlockInfo({
    required this.text,
    required this.lines,
    required this.boundingBox,
  });
}
