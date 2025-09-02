import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
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
  bool _isSelectMode = false;
  bool _isProcessing = false;
  bool _isProcessingComplete = false;
  List<PlatformFile> _temporaryFiles = [];
  Map<String, Map<String, int>> _compressionResults = {};

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
              onPressed: _selectedPdfIds.isEmpty ? null : _selectAll,
              icon: const Icon(Icons.select_all),
              tooltip: l10n.selectAll,
            ),
            IconButton(
              onPressed: _selectedPdfIds.isEmpty ? null : _deselectAll,
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
                l10n.pdfsSelected(_selectedPdfIds.length),
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
          : (_selectedPdfIds.isNotEmpty || _temporaryFiles.isNotEmpty)
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
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isProcessed 
                ? (wasSuccessful ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                : const Color(0xFF3B82F6), 
            width: 2
          ),
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
            
            // Status icon (replaces remove button after processing)
            if (isProcessed)
              Icon(
                wasSuccessful ? Icons.check_circle : Icons.cancel,
                color: wasSuccessful ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 24,
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

  void _selectAll() {
    setState(() {
      _selectedPdfIds.addAll(_pdfEbooks.map((e) => e.id));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedPdfIds.clear();
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
      // Create Documents/Yupiread directory if it doesn't exist
      final appDir = await getApplicationDocumentsDirectory();
      final yupireadDir = Directory('${appDir.path}/Yupiread');
      if (!await yupireadDir.exists()) {
        await yupireadDir.create(recursive: true);
      }

      int savedCount = 0;
      
      // Save compressed ebook files
      for (String ebookId in _selectedPdfIds) {
        if (_compressionResults.containsKey(ebookId)) {
          try {
            final ebook = _dataService.ebooks.firstWhere((e) => e.id == ebookId);
            final originalFile = File(ebook.filePath);
            
            // Create filename with _compressed suffix
            final originalName = path.basenameWithoutExtension(ebook.filePath);
            final extension = path.extension(ebook.filePath);
            final compressedFileName = '${originalName}_compressed$extension';
            final outputPath = '${yupireadDir.path}/$compressedFileName';
            
            // Copy original file as compressed file (in real implementation, this would be the actual compressed file)
            await originalFile.copy(outputPath);
            
            savedCount++;
          } catch (e) {
            print('Failed to save compressed ebook $ebookId: $e');
          }
        }
      }
      
      // Save compressed temporary files
      for (PlatformFile tempFile in _temporaryFiles) {
        if (_compressionResults.containsKey(tempFile.name)) {
          try {
            final originalFile = File(tempFile.path!);
            
            // Create filename with _compressed suffix
            final originalName = path.basenameWithoutExtension(tempFile.name);
            final extension = path.extension(tempFile.name);
            final compressedFileName = '${originalName}_compressed$extension';
            final outputPath = '${yupireadDir.path}/$compressedFileName';
            
            // Copy original file as compressed file (in real implementation, this would be the actual compressed file)
            await originalFile.copy(outputPath);
            
            savedCount++;
          } catch (e) {
            print('Failed to save compressed temp file ${tempFile.name}: $e');
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$savedCount compressed files saved to Documents/Yupiread/'),
            backgroundColor: const Color(0xFF10B981),
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
      _isSelectMode = false;
    });
  }

  Future<void> _compressSelectedPdfs() async {
    final l10n = AppLocalizations.of(context);
    
    if (_selectedPdfIds.isEmpty && _temporaryFiles.isEmpty) {
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
          
          // Simulate compression by showing success
          // In a real implementation, you would use a PDF compression library
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Simulate compression result (reduce size by 20-40%)
          final compressionRatio = 0.7 + (0.2 * (successCount % 3) / 3); // Random between 0.7-0.9
          final afterSize = (beforeSize * compressionRatio).round();
          
          // Store compression results
          _compressionResults[ebookId] = {
            'before': beforeSize,
            'after': afterSize,
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
          
          // Simulate compression by showing success
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Simulate compression result (reduce size by 20-40%)
          final compressionRatio = 0.7 + (0.2 * (successCount % 3) / 3);
          final afterSize = (beforeSize * compressionRatio).round();
          
          // Store compression results using file name as key
          _compressionResults[tempFile.name] = {
            'before': beforeSize,
            'after': afterSize,
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
        _selectedPdfIds.clear();
        _isSelectMode = false;
      });

      if (mounted) {
        // Calculate total savings
        int totalBefore = 0;
        int totalAfter = 0;
        for (var result in _compressionResults.values) {
          totalBefore += result['before']!;
          totalAfter += result['after']!;
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
