import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/data_service.dart';
import '../models/ebook_model.dart';
import '../l10n/app_localizations.dart';

class PdfMergeScreen extends StatefulWidget {
  const PdfMergeScreen({super.key});

  @override
  State<PdfMergeScreen> createState() => _PdfMergeScreenState();
}

class _PdfMergeScreenState extends State<PdfMergeScreen> {
  final DataService _dataService = DataService.instance;
  final Set<String> _selectedPdfIds = <String>{};
  bool _isSelectMode = false;
  bool _isProcessing = false;
  bool _isProcessingComplete = false;
  List<PlatformFile> _temporaryFiles = [];
  String? _mergedFilePath;

  List<EbookModel> get _pdfEbooks {
    return _dataService.ebooks.where((ebook) => ebook.fileType == 'pdf').toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.selectPdfsToMerge,
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
                        return _buildPdfCard(ebook, isSelected, l10n, index);
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
          : ((_selectedPdfIds.length + _temporaryFiles.length) >= 2)
              ? FloatingActionButton.extended(
                  onPressed: _isProcessing ? null : _mergeSelectedPdfs,
                  icon: _isProcessing 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.merge),
                  label: Text(_isProcessing ? l10n.merging : l10n.merge),
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
                      label: const Text('Merge More'),
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
            onPressed: _addFilesFromManager,
            icon: const Icon(Icons.add),
            label: Text(l10n.addFromFileManager),
          ),
        ],
      ),
    );
  }

  Widget _buildTempFileCard(PlatformFile file, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3B82F6), width: 2),
        ),
        child: Row(
          children: [
            // PDF Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                color: Color(0xFF3B82F6),
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
                  Text(
                    'Selected for merging',
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
                ],
              ),
            ),
            
            // Remove button
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

  Widget _buildPdfCard(EbookModel ebook, bool isSelected, AppLocalizations l10n, int index) {
    return Card(
      key: ValueKey(ebook.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
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
            border: isSelected
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
          ),
          child: Row(
            children: [
              // Drag handle
              if (_isSelectMode && _selectedPdfIds.length >= 2)
                const Icon(
                  Icons.drag_handle,
                  color: Colors.grey,
                ),
              if (_isSelectMode && _selectedPdfIds.length >= 2)
                const SizedBox(width: 8),
              
              // Order number
              if (_isSelectMode && isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${_getOrderNumber(ebook.id)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (_isSelectMode && isSelected)
                const SizedBox(width: 12),
              
              // PDF Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Color(0xFF10B981),
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
              
              // Selection indicator
              if (_isSelectMode)
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  int _getOrderNumber(String ebookId) {
    final selectedList = _selectedPdfIds.toList();
    return selectedList.indexOf(ebookId) + 1;
  }

  void _addFilesFromManager() async {
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
              content: Text('${result.files.length} PDF files selected for merging'),
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
      if (_mergedFilePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No merged file to save'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      // Import the merged PDF as an ebook
      final mergedTitle = 'Merged PDF - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
      await _dataService.importPdfFile(_mergedFilePath!, customTitle: mergedTitle);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merged PDF saved to ebook library'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save document: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _resetScreen() {
    setState(() {
      _isProcessingComplete = false;
      _mergedFilePath = null;
      _temporaryFiles.clear();
      _selectedPdfIds.clear();
      _isSelectMode = false;
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    setState(() {
      final ebook = _pdfEbooks.removeAt(oldIndex);
      _pdfEbooks.insert(newIndex, ebook);
    });
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


  Future<void> _mergeSelectedPdfs() async {
    final l10n = AppLocalizations.of(context);
    
    if ((_selectedPdfIds.length + _temporaryFiles.length) < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectAtLeastTwoPdfs),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Prepare file paths for merging from both selected ebooks and temporary files
      final inputPaths = <String>[];
      
      // Add selected ebooks
      final selectedEbooks = _selectedPdfIds
          .map((id) => _dataService.ebooks.firstWhere((e) => e.id == id))
          .toList();
      inputPaths.addAll(selectedEbooks.map((e) => e.filePath));
      
      // Add temporary files
      for (final tempFile in _temporaryFiles) {
        if (tempFile.path != null) {
          inputPaths.add(tempFile.path!);
        }
      }

      // Create output path
      final appDir = await getApplicationDocumentsDirectory();
      final yupireadDir = Directory('${appDir.path}/Yupiread');
      if (!await yupireadDir.exists()) {
        await yupireadDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${yupireadDir.path}/merged_pdf_$timestamp.pdf';

      // Merge PDFs using pdf_combiner
      await PdfCombiner.mergeMultiplePDFs(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      // Don't import merged PDF as ebook automatically - let user decide with Save Documents button
      final mergedTitle = 'Merged PDF - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

      setState(() {
        _isProcessing = false;
        _isProcessingComplete = true;
        _mergedFilePath = outputPath;
        _selectedPdfIds.clear();
        _isSelectMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mergeComplete),
            backgroundColor: const Color(0xFF10B981),
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
            content: Text('${l10n.mergeFailed}: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
