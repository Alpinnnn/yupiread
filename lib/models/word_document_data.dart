import 'package:syncfusion_flutter_pdf/pdf.dart';

// Model untuk menyimpan data dokumen Word yang diekstrak
class WordDocumentData {
  List<WordElement> elements = [];
  Map<String, List<int>> images = {};
  Map<String, String> relationships = {};
}

// Model untuk elemen dalam dokumen Word
class WordElement {
  String type; // 'paragraph', 'image', 'table', dll
  String text = '';
  String? imageId;
  WordFormatting formatting;
  bool isHeader = false;
  int headerLevel = 1;

  WordElement({
    required this.type,
    this.text = '',
    this.imageId,
    WordFormatting? formatting,
    this.isHeader = false,
    this.headerLevel = 1,
  }) : formatting = formatting ?? WordFormatting();
}

// Model untuk formatting teks
class WordFormatting {
  bool isBold = false;
  bool isItalic = false;
  bool isUnderline = false;
  double fontSize = 11.0;
  PdfColor? color;
  PdfColor? backgroundColor;

  WordFormatting({
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.fontSize = 11.0,
    this.color,
    this.backgroundColor,
  });
}
