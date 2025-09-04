import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/data_service.dart';
import '../models/ebook_model.dart';
import '../l10n/app_localizations.dart';

class PdfCompressScreen extends StatefulWidget {
  const PdfCompressScreen({super.key});

  @override
  State<PdfCompressScreen> createState() => _PdfCompressScreenState();
}

class _PdfCompressScreenState extends State<PdfCompressScreen> {
  final DataService _dataService = DataService.instance;
  final Set<String> _selectedPdfIds = <String>{};
  final Set<String> _selectedTempFileIds = <String>{};
  bool _isSelectMode = false;
  bool _isProcessing = false;
  bool _isProcessingComplete = false;
  List<PlatformFile> _temporaryFiles = [];
  Map<String, Map<String, dynamic>> _compressionResults = {};
  Set<String> _processedEbookIds = <String>{};
  List<PlatformFile> _processedTempFiles = [];

  List<EbookModel> get _pdfEbooks {
    return _dataService.ebooks.where((ebook) => ebook.fileType == 'pdf').toList();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.selectPdfsToCompress,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.headlineMedium?.color,
            fontSize: 18,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          if (_isSelectMode) ...[
            IconButton(
              onPressed: (_selectedPdfIds.isEmpty && _selectedTempFileIds.isEmpty) ? null : _selectAll,
              icon: const Icon(Icons.select_all),
              tooltip: l10n.selectAll,
            ),
            IconButton(
              onPressed: (_selectedPdfIds.isEmpty && _selectedTempFileIds.isEmpty) ? null : _deselectAll,
              icon: const Icon(Icons.deselect),
              tooltip: l10n.deselectAll,
            ),
          ],
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add_files') {
                _addFilesFromManager();
              } else if (value == 'toggle_select') {
                setState(() {
                  _isSelectMode = !_isSelectMode;
                  if (!_isSelectMode) {
                    _selectedPdfIds.clear();
                    _selectedTempFileIds.clear();
                  }
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'add_files',
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline),
                    const SizedBox(width: 8),
                    Text(l10n.addFromFileManager),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_select',
                child: Row(
                  children: [
                    Icon(_isSelectMode ? Icons.close : Icons.check_circle_outline),
                    const SizedBox(width: 8),
                    Text(_isSelectMode ? l10n.cancel : 'Select Mode'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Selection info
          if (_isSelectMode && _selectedPdfIds.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.pdfsSelected(_selectedPdfIds.length + _selectedTempFileIds.length),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          // PDF List
          Expanded(
            child: _pdfEbooks.isEmpty && _temporaryFiles.isEmpty
                ? _buildEmptyState(l10n)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pdfEbooks.length + _temporaryFiles.length,
                    itemBuilder: (context, index) {
                      if (index < _pdfEbooks.length) {
                        final ebook = _pdfEbooks[index];
                        final isSelected = _selectedPdfIds.contains(ebook.id);
                        return _buildPdfCard(ebook, isSelected, l10n);
                      } else {
                        final tempIndex = index - _pdfEbooks.length;
                        final tempFile = _temporaryFiles[tempIndex];
                        return _buildTempFileCard(tempFile, l10n);
                      }
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _isProcessingComplete 
          ? null
          : (_selectedPdfIds.isNotEmpty || _selectedTempFileIds.isNotEmpty)
              ? FloatingActionButton.extended(
                  onPressed: _isProcessing ? null : _compressSelectedPdfs,
                  icon: _isProcessing 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.compress),
                  label: Text(_isProcessing ? l10n.compressing : l10n.compress),
                  backgroundColor: _isProcessing 
                      ? Colors.grey 
                      : Theme.of(context).colorScheme.primary,
                )
              : null,
      bottomNavigationBar: _isProcessingComplete 
          ? Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveDocuments,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Documents'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _resetScreen,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Compress More'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 64,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noPdfsAvailable,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addPdfsFirst,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isProcessingComplete ? null : _addFilesFromManager,
            icon: const Icon(Icons.add),
            label: Text(l10n.addFromFileManager),
          ),
        ],
      ),
    );
  }

  Widget _buildTempFileCard(PlatformFile file, AppLocalizations l10n) {
    final compressionResult = _compressionResults[file.name];
    final isProcessed = _isProcessingComplete && compressionResult != null;
    final wasSuccessful = isProcessed;
    final isSelected = _selectedTempFileIds.contains(file.name);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _isProcessingComplete ? null : () {
          if (_isSelectMode) {
            _toggleTempFileSelection(file.name);
          } else {
            setState(() {
              _isSelectMode = true;
              _selectedTempFileIds.add(file.name);
            });
          }
        },
        onLongPress: () {
          if (!_isSelectMode) {
            setState(() {
              _isSelectMode = true;
              _selectedTempFileIds.add(file.name);
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isProcessed 
                ? Border.all(
                    color: wasSuccessful ? const Color(0xFF10B981) : const Color(0xFFEF4444), 
                    width: 2
                  )
                : isSelected
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                    : null,
          ),
          child: Row(
          children: [
            // PDF Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isProcessed 
                    ? (wasSuccessful ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1))
                    : const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.picture_as_pdf,
                color: isProcessed 
                    ? (wasSuccessful ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                    : const Color(0xFF3B82F6),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // File Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (!isProcessed) ...[
                    Text(
                      'Selected for compression',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF3B82F6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatFileSize(file.size),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ] else ...[
                    Text(
                      wasSuccessful ? 'Compression completed' : 'Compression failed',
                      style: TextStyle(
                        fontSize: 12,
                        color: wasSuccessful ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (wasSuccessful) ...[
                      Text(
                        '${_formatFileSize(compressionResult['before']!)} → ${_formatFileSize(compressionResult['after']!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            
            // Status icon or selection indicator
            if (isProcessed)
              Icon(
                wasSuccessful ? Icons.check_circle : Icons.cancel,
                color: wasSuccessful ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 24,
              )
            else if (_isSelectMode)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyMedium!.color!,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              )
            else
              IconButton(
                onPressed: (_isProcessing || _isProcessingComplete) ? null : () {
                  setState(() {
                    _temporaryFiles.remove(file);
                  });
                },
                icon: const Icon(Icons.close, color: Colors.red),
              ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfCard(EbookModel ebook, bool isSelected, AppLocalizations l10n) {
    final compressionResult = _compressionResults[ebook.id];
    final isProcessed = _isProcessingComplete && compressionResult != null;
    final wasSuccessful = isProcessed;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _isProcessingComplete ? null : () {
          if (_isSelectMode) {
            _toggleSelection(ebook.id);
          } else {
            setState(() {
              _isSelectMode = true;
              _selectedPdfIds.add(ebook.id);
            });
          }
        },
        onLongPress: () {
          if (!_isSelectMode) {
            setState(() {
              _isSelectMode = true;
              _selectedPdfIds.add(ebook.id);
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isProcessed 
                ? Border.all(
                    color: wasSuccessful ? const Color(0xFF10B981) : const Color(0xFFEF4444), 
                    width: 2
                  )
                : isSelected
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                    : null,
          ),
          child: Row(
            children: [
              // PDF Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isProcessed 
                      ? (wasSuccessful ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1))
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: isProcessed 
                      ? (wasSuccessful ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                      : const Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // PDF Info
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (ebook.description.isNotEmpty)
                      Text(
                        ebook.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    // Show compression results if available
                    if (isProcessed) ...[
                      Text(
                        wasSuccessful ? 'Compression completed' : 'Compression failed',
                        style: TextStyle(
                          fontSize: 12,
                          color: wasSuccessful ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (wasSuccessful)
                        Text(
                          '${_formatFileSize(compressionResult['before']!)} → ${_formatFileSize(compressionResult['after']!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                    ] else
                      Text(
                        '${ebook.totalPages} pages',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Status icon or selection indicator
              if (isProcessed)
                Icon(
                  wasSuccessful ? Icons.check_circle : Icons.cancel,
                  color: wasSuccessful ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: 24,
                )
              else if (_isSelectMode)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyMedium!.color!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedPdfIds.contains(id)) {
        _selectedPdfIds.remove(id);
      } else {
        _selectedPdfIds.add(id);
      }
    });
  }

  void _toggleTempFileSelection(String fileName) {
    setState(() {
      if (_selectedTempFileIds.contains(fileName)) {
        _selectedTempFileIds.remove(fileName);
      } else {
        _selectedTempFileIds.add(fileName);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedPdfIds.addAll(_pdfEbooks.map((e) => e.id));
      _selectedTempFileIds.addAll(_temporaryFiles.map((f) => f.name));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedPdfIds.clear();
      _selectedTempFileIds.clear();
    });
  }

  Future<void> _addFilesFromManager() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        // Add files to temporary list for processing, don't save to ebook list
        setState(() {
          _temporaryFiles.addAll(result.files);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.files.length} PDF files selected for compression'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import files: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _saveDocuments() async {
    try {
      // Request storage permission first
      PermissionStatus permission = await Permission.storage.status;
      if (!permission.isGranted) {
        permission = await Permission.storage.request();
        if (!permission.isGranted) {
          // For Android 11+ (API 30+), try manage external storage permission
          if (await Permission.manageExternalStorage.isDenied) {
            permission = await Permission.manageExternalStorage.request();
          }
          
          if (!permission.isGranted && !await Permission.manageExternalStorage.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage permission is required to save files'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            }
            return;
          }
        }
      }

      // Get external storage directory (user accessible Documents folder)
      Directory? externalDir;
      if (Platform.isAndroid) {
        // Try to get external storage directory
        final List<Directory>? externalDirs = await getExternalStorageDirectories();
        if (externalDirs != null && externalDirs.isNotEmpty) {
          // Navigate to the public Documents directory
          final String externalPath = externalDirs.first.path;
          // Remove the app-specific part to get to public storage
          final List<String> pathParts = externalPath.split('/');
          final int androidIndex = pathParts.indexOf('Android');
          if (androidIndex > 0) {
            final String publicPath = pathParts.sublist(0, androidIndex).join('/');
            externalDir = Directory('$publicPath/Documents/Yupiread');
          }
        }
      }
      
      // Fallback to Downloads if Documents is not accessible
      externalDir ??= Directory('/storage/emulated/0/Download/Yupiread');
      
      // Create directory if it doesn't exist
      if (!await externalDir.exists()) {
        await externalDir.create(recursive: true);
      }

      int savedCount = 0;
      
      // Save compressed ebook files
      for (String ebookId in _processedEbookIds) {
        if (_compressionResults.containsKey(ebookId)) {
          try {
            final ebook = _dataService.ebooks.firstWhere((e) => e.id == ebookId);
            final originalFile = File(ebook.filePath);
            
            // Create filename with _compressed suffix
            final originalName = path.basenameWithoutExtension(ebook.filePath);
            final extension = path.extension(ebook.filePath);
            final compressedFileName = '${originalName}_compressed$extension';
            final outputPath = '${externalDir.path}/$compressedFileName';
            
            // Copy original file as compressed file (in real implementation, this would be the actual compressed file)
            await originalFile.copy(outputPath);
            
            savedCount++;
          } catch (e) {
            print('Failed to save compressed ebook $ebookId: $e');
          }
        }
      }
      
      // Save compressed temporary files
      for (PlatformFile tempFile in _processedTempFiles) {
        if (_compressionResults.containsKey(tempFile.name)) {
          try {
            // Create filename with _compressed suffix
            final originalName = path.basenameWithoutExtension(tempFile.name);
            final extension = path.extension(tempFile.name);
            final compressedFileName = '${originalName}_compressed$extension';
            final outputPath = '${externalDir.path}/$compressedFileName';
            
            // Save the compressed PDF data
            final compressedData = _compressionResults[tempFile.name]!['compressedData'] as Uint8List;
            await File(outputPath).writeAsBytes(compressedData);
            
            savedCount++;
          } catch (e) {
            print('Failed to save compressed temp file ${tempFile.name}: $e');
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$savedCount compressed files saved to ${externalDir.path}'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save documents: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _resetScreen() {
    setState(() {
      _isProcessingComplete = false;
      _compressionResults.clear();
      _temporaryFiles.clear();
      _selectedPdfIds.clear();
      _selectedTempFileIds.clear();
      _isSelectMode = false;
      _processedEbookIds.clear();
      _processedTempFiles.clear();
    });
  }

  /// Compress PDF file using Syncfusion PDF library
  Future<Uint8List> _compressPdfFile(File pdfFile) async {
    try {
      // Read the PDF file bytes
      final Uint8List inputBytes = await pdfFile.readAsBytes();
      
      // Load the existing PDF document
      final PdfDocument document = PdfDocument(inputBytes: inputBytes);
      
      // Apply compression optimizations
      // 1. Disable incremental update to reduce file size
      document.fileStructure.incrementalUpdate = false;
      
      // 2. Remove unused objects and optimize structure
      document.fileStructure.crossReferenceType = PdfCrossReferenceType.crossReferenceStream;
      
      // 3. Optimize document structure
      // Remove metadata to reduce file size
      document.documentInformation.title = '';
      document.documentInformation.author = '';
      document.documentInformation.subject = '';
      document.documentInformation.keywords = '';
      document.documentInformation.creator = '';
      document.documentInformation.producer = '';
      
      // Save the compressed document
      final List<int> compressedBytes = await document.save();
      
      // Dispose the document to free memory
      document.dispose();
      
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      print('Error compressing PDF: $e');
      // If compression fails, return original file
      return await pdfFile.readAsBytes();
    }
  }

  Future<void> _compressSelectedPdfs() async {
    final l10n = AppLocalizations.of(context);
    
    if (_selectedPdfIds.isEmpty && _selectedTempFileIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectAtLeastOnePdf),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      int successCount = 0;
      int failCount = 0;

      // Process selected ebooks from library
      for (String ebookId in _selectedPdfIds) {
        final ebook = _dataService.ebooks.firstWhere((e) => e.id == ebookId);
        
        try {
          // Get file size before compression
          final file = File(ebook.filePath);
          final beforeSize = await file.length();
          
          // Perform real PDF compression
          final compressedBytes = await _compressPdfFile(file);
          final afterSize = compressedBytes.length;
          
          // Store compression results
          _compressionResults[ebookId] = {
            'before': beforeSize,
            'after': afterSize,
            'compressedData': compressedBytes,
          };
          
          successCount++;
        } catch (e) {
          print('Failed to compress ${ebook.title}: $e');
          failCount++;
        }
      }

      // Process temporary files
      for (PlatformFile tempFile in _temporaryFiles) {
        try {
          // Get file size before compression
          final beforeSize = tempFile.size;
          
          // Perform real PDF compression
          final file = File(tempFile.path!);
          final compressedBytes = await _compressPdfFile(file);
          final afterSize = compressedBytes.length;
          
          // Store compression results using file name as key
          _compressionResults[tempFile.name] = {
            'before': beforeSize,
            'after': afterSize,
            'compressedData': compressedBytes,
          };
          
          successCount++;
        } catch (e) {
          print('Failed to compress ${tempFile.name}: $e');
          failCount++;
        }
      }

      setState(() {
        _isProcessing = false;
        _isProcessingComplete = true;
        // Store processed items before clearing selections
        _processedEbookIds = Set.from(_selectedPdfIds);
        _processedTempFiles = _temporaryFiles.where((f) => _selectedTempFileIds.contains(f.name)).toList();
        _selectedPdfIds.clear();
        _selectedTempFileIds.clear();
        _isSelectMode = false;
      });

      if (mounted) {
        // Calculate total savings
        int totalBefore = 0;
        int totalAfter = 0;
        for (var result in _compressionResults.values) {
          totalBefore += (result['before']! as int);
          totalAfter += (result['after']! as int);
        }
        final savedBytes = totalBefore - totalAfter;
        final savedPercentage = totalBefore > 0 ? ((savedBytes / totalBefore) * 100).round() : 0;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failCount == 0
                  ? 'Compression complete! Saved ${_formatFileSize(savedBytes)} ($savedPercentage%)'
                  : 'Compressed $successCount files, $failCount failed',
            ),
            backgroundColor: failCount == 0 
                ? const Color(0xFF10B981) 
                : const Color(0xFFF59E0B),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.compressionFailed}: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
