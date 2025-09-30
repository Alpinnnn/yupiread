import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../services/data_service.dart';
import '../models/ebook_model.dart';
import 'ebook_reader_screen.dart';
import 'document_scanner_screen.dart';

class PdfScannerScreen extends StatefulWidget {
  const PdfScannerScreen({super.key});

  @override
  State<PdfScannerScreen> createState() => _PdfScannerScreenState();
}

class _PdfScannerScreenState extends State<PdfScannerScreen> {
  final DataService _dataService = DataService.instance;
  List<String> _scannedImages = [];
  bool _isProcessing = false;
  bool _isScanning = false;
  List<EbookModel> _scannedPdfs = [];
  bool _isLoadingFiles = true;
  bool _isSelectMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadScannedFiles();
  }

  Future<void> _loadScannedFiles() async {
    setState(() {
      _isLoadingFiles = true;
    });

    try {
      // Get all ebooks
      final allEbooks = _dataService.ebooks;
      
      // Filter only scanned PDFs (title starts with "Scanned Document")
      final scannedFiles = allEbooks.where((ebook) {
        return ebook.title.startsWith('Scanned Document') && ebook.fileType == 'pdf';
      }).toList();

      // Sort by creation date (newest first)
      scannedFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _scannedPdfs = scannedFiles;
        _isLoadingFiles = false;
      });
    } catch (e) {
      print('Error loading scanned files: $e');
      setState(() {
        _isLoadingFiles = false;
      });
    }
  }

  Future<void> _scanDocument() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentScannerScreen(
          useGallery: false,
          onDocumentsScanned: (List<String> scannedImagePaths) {
            if (scannedImagePaths.isNotEmpty) {
              setState(() {
                _scannedImages.addAll(scannedImagePaths);
              });
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${scannedImagePaths.length} pages scanned successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _convertToPdf() async {
    if (_scannedImages.isEmpty) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.scanAtLeastOnePage),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final l10n = AppLocalizations.of(context);
      
      // Create PDF document
      final pdf = pw.Document();

      // Add each scanned image as a page - FILL ENTIRE PAGE
      for (final imagePath in _scannedImages) {
        final imageFile = File(imagePath);
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        // Get image dimensions to determine orientation
        final decodedImage = await decodeImageFromList(imageBytes);
        final isLandscape = decodedImage.width > decodedImage.height;
        
        final pageFormat = isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.zero, // No margins - fill entire page
            build: (pw.Context context) {
              return pw.Container(
                width: pageFormat.width,
                height: pageFormat.height,
                child: pw.Image(
                  image,
                  fit: pw.BoxFit.cover, // Cover entire page, crop if needed
                ),
              );
            },
          ),
        );
      }

      // Save PDF to ebooks directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory ebooksDir = Directory(path.join(appDir.path, 'ebooks'));
      if (!await ebooksDir.exists()) {
        await ebooksDir.create(recursive: true);
      }

      final String fileName = 'scanned_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final String pdfPath = path.join(ebooksDir.path, fileName);
      final File pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await pdf.save());

      // Add to ebook list
      final availableTags = _dataService.availableTags;
      final defaultTag = availableTags.contains('scanned') ? 'scanned' : availableTags.first;
      
      final ebookId = await _dataService.addEbook(
        title: 'Scanned Document ${DateTime.now().toString().split(' ')[0]}',
        filePath: pdfPath,
        description: l10n.pdfScannerDesc,
        tags: [defaultTag],
        fileType: 'pdf',
      );

      setState(() {
        _isProcessing = false;
      });

      // Clean up scanned images
      for (final imagePath in _scannedImages) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Error deleting temp file: $e');
        }
      }

      // Reset state and reload files
      setState(() {
        _scannedImages.clear();
        _isScanning = false;
      });
      await _loadScannedFiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pdfCreated),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to ebook reader
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EbookReaderScreen(ebookId: ebookId),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      print('Error converting to PDF: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.pdfCreationFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<ui.Image> decodeImageFromList(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _removePage(int index) {
    setState(() {
      final imagePath = _scannedImages[index];
      _scannedImages.removeAt(index);
      
      // Delete the temp file
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        print('Error deleting file: $e');
      }
    });
  }

  Future<void> _deleteScannedFile(String ebookId) async {
    try {
      final l10n = AppLocalizations.of(context);
      
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteDocument),
          content: Text(l10n.deleteConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _dataService.deleteEbook(ebookId);
        await _loadScannedFiles();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePdfToExternalStorage(String ebookId) async {
    try {
      final l10n = AppLocalizations.of(context);
      
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(l10n.savingPdf),
              ],
            ),
          ),
        );
      }

      // Get the ebook
      final ebook = _dataService.ebooks.firstWhere((e) => e.id == ebookId);
      final sourceFile = File(ebook.filePath);

      if (!await sourceFile.exists()) {
        throw Exception('Source file not found');
      }

      // Request storage permission for Android 10 and below
      if (Platform.isAndroid) {
        final androidVersion = await _getAndroidVersion();
        if (androidVersion <= 29) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            throw Exception('Storage permission denied');
          }
        } else if (androidVersion >= 30) {
          // For Android 11+, use manageExternalStorage permission
          final status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            // Fall back to regular storage permission
            final storageStatus = await Permission.storage.request();
            if (!storageStatus.isGranted) {
              throw Exception('Storage permission denied');
            }
          }
        }
      }

      // Get external storage directory
      Directory? externalDir;
      if (Platform.isAndroid) {
        // For Android, use /storage/emulated/0/Documents/Yupiread
        externalDir = Directory('/storage/emulated/0/Documents/Yupiread');
      } else {
        // For other platforms, fall back to app documents
        externalDir = await getApplicationDocumentsDirectory();
      }

      // Create directory if it doesn't exist
      if (!await externalDir.exists()) {
        await externalDir.create(recursive: true);
      }

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${ebook.title.replaceAll(' ', '_')}_$timestamp.pdf';
      final destinationPath = path.join(externalDir.path, fileName);

      // Copy the file
      await sourceFile.copy(destinationPath);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show success toast
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.pdfSavedTo}: $destinationPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      print('Error saving PDF: $e');
      
      // Close loading dialog if open
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error message
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToSavePdf}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      // Get Android version from system
      final androidInfo = await Future.value(30); // Default to 30 for safety
      return androidInfo;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // If processing, show loading
    if (_isProcessing) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(l10n.pdfScanner),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                l10n.convertingToPdf,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }
    
    // If scanning, show scan preview
    if (_isScanning || _scannedImages.isNotEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(l10n.pdfScanner),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Clear scanned images and go back to list
              setState(() {
                _scannedImages.clear();
                _isScanning = false;
              });
            },
          ),
        ),
        body: _scannedImages.isEmpty
            ? _buildScanningEmptyState(l10n)
            : _buildScannedPages(l10n),
        floatingActionButton: _scannedImages.isEmpty
            ? FloatingActionButton.extended(
                onPressed: _scanDocument,
                icon: const Icon(Icons.document_scanner),
                label: Text(l10n.scanToPdf),
                backgroundColor: const Color(0xFF8B5CF6),
              )
            : FloatingActionButton.extended(
                onPressed: _convertToPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(l10n.createPdf),
                backgroundColor: const Color(0xFF8B5CF6),
              ),
      );
    }
    
    // Default: Show scanned files list
    final selectedCount = _selectedIds.length;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isSelectMode ? '$selectedCount selected' : l10n.scannedFiles),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: _isSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectMode = false;
                    _selectedIds.clear();
                  });
                },
              )
            : null,
        actions: _isSelectMode
            ? [
                if (selectedCount > 0 && selectedCount == _scannedPdfs.length)
                  IconButton(
                    icon: const Icon(Icons.deselect),
                    onPressed: () {
                      setState(() {
                        _selectedIds.clear();
                      });
                    },
                    tooltip: 'Deselect All',
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    onPressed: () {
                      setState(() {
                        _selectedIds = _scannedPdfs.map((e) => e.id).toSet();
                      });
                    },
                    tooltip: 'Select All',
                  ),
              ]
            : null,
      ),
      body: _isLoadingFiles
          ? const Center(child: CircularProgressIndicator())
          : _scannedPdfs.isEmpty
              ? _buildEmptyScannedFilesState(l10n)
              : _buildScannedFilesList(l10n),
      floatingActionButton: _isSelectMode && selectedCount > 0
          ? FloatingActionButton(
              onPressed: _showSelectedItemsOptions,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.more_vert, color: Colors.white),
            )
          : FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _isScanning = true;
                  _scannedImages.clear();
                });
                _scanDocument();
              },
              icon: const Icon(Icons.document_scanner),
              label: Text(l10n.scanNewDocument),
              backgroundColor: const Color(0xFF8B5CF6),
            ),
    );
  }

  Widget _buildEmptyScannedFilesState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.folder_outlined,
                size: 80,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noScannedFilesYet,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.startScanning,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.document_scanner,
                size: 80,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noImagesScanned,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.pdfScannerDesc,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannedFilesList(AppLocalizations l10n) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _scannedPdfs.length,
      itemBuilder: (context, index) {
        final ebook = _scannedPdfs[index];
        final isSelected = _selectedIds.contains(ebook.id);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _isSelectMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(ebook.id);
                        } else {
                          _selectedIds.remove(ebook.id);
                        }
                      });
                    },
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      color: Color(0xFF8B5CF6),
                      size: 28,
                    ),
                  ),
            title: Text(
              ebook.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              ebook.timeAgo,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: _isSelectMode
                ? null
                : PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            const Icon(Icons.visibility, size: 20),
                            const SizedBox(width: 12),
                            Text(l10n.viewDocument),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            const Icon(Icons.share, size: 20, color: Color(0xFF2563EB)),
                            const SizedBox(width: 12),
                            const Text('Share', style: TextStyle(color: Color(0xFF2563EB))),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'save',
                        child: Row(
                          children: [
                            const Icon(Icons.save, size: 20, color: Color(0xFF10B981)),
                            const SizedBox(width: 12),
                            Text(l10n.savePdf, style: const TextStyle(color: Color(0xFF10B981))),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 20, color: Colors.red),
                            const SizedBox(width: 12),
                            Text(l10n.deleteDocument, style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'view') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EbookReaderScreen(ebookId: ebook.id),
                          ),
                        );
                      } else if (value == 'share') {
                        _shareSingleItem(ebook.id);
                      } else if (value == 'save') {
                        _savePdfToExternalStorage(ebook.id);
                      } else if (value == 'delete') {
                        _deleteScannedFile(ebook.id);
                      }
                    },
                  ),
            onTap: () {
              if (_isSelectMode) {
                setState(() {
                  if (isSelected) {
                    _selectedIds.remove(ebook.id);
                  } else {
                    _selectedIds.add(ebook.id);
                  }
                });
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EbookReaderScreen(ebookId: ebook.id),
                  ),
                );
              }
            },
            onLongPress: () {
              if (!_isSelectMode) {
                setState(() {
                  _isSelectMode = true;
                  _selectedIds.add(ebook.id);
                });
              }
            },
          ),
        );
      },
    );
  }

  void _showSelectedItemsOptions() {
    final selectedCount = _selectedIds.length;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
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
              '$selectedCount item selected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.delete,
              title: 'Delete',
              subtitle: 'Delete selected PDF files',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _deleteSelectedItems();
              },
            ),
            _buildOptionTile(
              icon: Icons.share,
              title: 'Share',
              subtitle: 'Share selected PDF files',
              color: const Color(0xFF2563EB),
              onTap: () {
                Navigator.pop(context);
                _shareSelectedItems();
              },
            ),
            _buildOptionTile(
              icon: Icons.save,
              title: 'Save PDF',
              subtitle: 'Save to Documents/Yupiread',
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(context);
                _saveSelectedItemsToExternal();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  Future<void> _deleteSelectedItems() async {
    final count = _selectedIds.length;
    
    for (String id in _selectedIds) {
      await _dataService.deleteEbook(id);
    }
    await _loadScannedFiles();
    setState(() {
      _isSelectMode = false;
      _selectedIds.clear();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count files deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _shareSingleItem(String ebookId) async {
    try {
      final ebook = _scannedPdfs.firstWhere((e) => e.id == ebookId);
      final file = File(ebook.filePath);
      
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Share single file using Android share dialog
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: ebook.title,
        text: 'Sharing scanned PDF document',
      );
    } catch (e) {
      print('Error sharing file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareSelectedItems() async {
    try {
      // Get file paths for selected items
      List<XFile> filesToShare = [];
      
      for (String id in _selectedIds) {
        final ebook = _scannedPdfs.firstWhere((e) => e.id == id);
        final file = File(ebook.filePath);
        
        if (await file.exists()) {
          filesToShare.add(XFile(file.path));
        }
      }
      
      if (filesToShare.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No files available to share'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Share using Android share dialog
      await Share.shareXFiles(
        filesToShare,
        subject: '${filesToShare.length} Scanned PDF Files',
        text: 'Sharing ${filesToShare.length} scanned PDF document${filesToShare.length > 1 ? 's' : ''}',
      );
      
      // Exit selection mode after sharing
      setState(() {
        _isSelectMode = false;
        _selectedIds.clear();
      });
    } catch (e) {
      print('Error sharing files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSelectedItemsToExternal() async {
    final count = _selectedIds.length;
    int savedCount = 0;
    
    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text('Saving $count files...'),
            ],
          ),
        ),
      );
    }
    
    try {
      for (String id in _selectedIds) {
        await _savePdfToExternalStorage(id);
        savedCount++;
      }
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      
      setState(() {
        _isSelectMode = false;
        _selectedIds.clear();
      });
      
      // Show success toast
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$savedCount Files Saved'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildScannedPages(AppLocalizations l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.pagesScanned(_scannedImages.length),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              TextButton.icon(
                onPressed: _scanDocument,
                icon: const Icon(Icons.add),
                label: Text(l10n.addMorePages),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableGridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: _scannedImages.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _scannedImages.removeAt(oldIndex);
                _scannedImages.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              return _buildPageCard(index, l10n);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPageCard(int index, AppLocalizations l10n) {
    return Card(
      key: ValueKey(_scannedImages[index]),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.file(
                    File(_scannedImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${l10n.pageTitle} ${index + 1}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                onPressed: () => _removePage(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up any remaining temp files if user exits without creating PDF
    for (final imagePath in _scannedImages) {
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        print('Error deleting temp file on dispose: $e');
      }
    }
    super.dispose();
  }
}
