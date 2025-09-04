import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'dart:typed_data';
import '../services/data_service.dart';
import '../models/photo_model.dart';
import '../l10n/app_localizations.dart';

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final DataService _dataService = DataService.instance;
  final List<String> _selectedItems = <String>[]; // Combined selection order
  bool _isSelectMode = false;
  bool _isProcessing = false;
  bool _isProcessingComplete = false;
  List<PlatformFile> _temporaryFiles = [];
  String? _convertedFilePath;

  List<PhotoModel> get _photos {
    return _dataService.photos;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Convert To PDF',
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
              onPressed: _selectedItems.isEmpty ? null : _selectAll,
              icon: const Icon(Icons.select_all),
              tooltip: l10n.selectAll,
            ),
            IconButton(
              onPressed: _selectedItems.isEmpty ? null : _deselectAll,
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
                    _selectedItems.clear();
                  }
                });
              }
            },
            itemBuilder:
                (context) => [
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
                        Icon(
                          _isSelectMode
                              ? Icons.close
                              : Icons.check_circle_outline,
                        ),
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
          // Image List
          Expanded(
            child:
                _photos.isEmpty && _temporaryFiles.isEmpty
                    ? _buildEmptyState(l10n)
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _photos.length + _temporaryFiles.length,
                      itemBuilder: (context, index) {
                        if (index < _photos.length) {
                          final photo = _photos[index];
                          final isSelected = _selectedItems.contains(photo.id);
                          return _buildPhotoCard(photo, isSelected, l10n);
                        } else {
                          final tempIndex = index - _photos.length;
                          final tempFile = _temporaryFiles[tempIndex];
                          return _buildTempFileCard(tempFile, l10n);
                        }
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton:
          _isProcessingComplete
              ? null
              : _selectedItems.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: _isProcessing ? null : _convertSelectedImages,
                icon:
                    _isProcessing
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.picture_as_pdf),
                label: Text(_isProcessing ? 'Converting...' : 'Convert to PDF'),
                backgroundColor:
                    _isProcessing
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary,
              )
              : null,
      bottomNavigationBar:
          _isProcessingComplete
              ? Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveDocument,
                        icon: const Icon(Icons.save),
                        label: const Text('Save PDF'),
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
                        label: const Text('Convert More'),
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
            Icons.image_outlined,
            size: 64,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          const SizedBox(height: 16),
          Text(
            'No images available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add images to convert to PDF',
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
    final isSelected = _selectedItems.contains('temp_${file.name}');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (_isSelectMode) {
            _toggleTempFileSelection(file.name);
          } else {
            setState(() {
              _isSelectMode = true;
              _selectedItems.add('temp_${file.name}');
            });
          }
        },
        onLongPress: () {
          if (!_isSelectMode) {
            setState(() {
              _isSelectMode = true;
              _selectedItems.add('temp_${file.name}');
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
                isSelected
                    ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                    : null,
          ),
          child: Row(
            children: [
              // Image Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.image,
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
                      isSelected ? 'Selected for conversion' : 'Tap to select',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isSelected
                                ? const Color(0xFF3B82F6)
                                : Theme.of(context).textTheme.bodyMedium?.color,
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

              // Order number indicator (replaces check icon) or Remove button
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
                      '${_getTempFileOrderNumber(file.name)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (_isSelectMode)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: Theme.of(context).textTheme.bodyMedium!.color!,
                      width: 2,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed:
                      (_isProcessing || _isProcessingComplete)
                          ? null
                          : () {
                            setState(() {
                              _temporaryFiles.remove(file);
                              _selectedItems.remove('temp_${file.name}');
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

  Widget _buildPhotoCard(
    PhotoModel photo,
    bool isSelected,
    AppLocalizations l10n,
  ) {
    return Card(
      key: ValueKey(photo.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (_isSelectMode) {
            _toggleSelection(photo.id);
          } else {
            setState(() {
              _isSelectMode = true;
              _selectedItems.add(photo.id);
            });
          }
        },
        onLongPress: () {
          if (!_isSelectMode) {
            setState(() {
              _isSelectMode = true;
              _selectedItems.add(photo.id);
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
                isSelected
                    ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                    : null,
          ),
          child: Row(
            children: [
              // Image Thumbnail
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(File(photo.imagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Photo Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photo.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (photo.description.isNotEmpty)
                      Text(
                        photo.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Foto dari galeri',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),

              // Order number indicator (replaces check icon)
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
                      '${_getOrderNumber(photo.id)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (_isSelectMode)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: Theme.of(context).textTheme.bodyMedium!.color!,
                      width: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  int _getOrderNumber(String photoId) {
    return _selectedItems.indexOf(photoId) + 1;
  }

  int _getTempFileOrderNumber(String fileName) {
    return _selectedItems.indexOf('temp_$fileName') + 1;
  }

  void _addFilesFromManager() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _temporaryFiles.addAll(result.files);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${result.files.length} images selected for conversion',
              ),
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

  void _saveDocument() async {
    try {
      if (_convertedFilePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No PDF file to save'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      // Request storage permission
      final storagePermission = await Permission.storage.request();
      final manageExternalStoragePermission =
          await Permission.manageExternalStorage.request();

      if (!storagePermission.isGranted &&
          !manageExternalStoragePermission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission required to save files'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
        return;
      }

      // Determine external directory path
      Directory? externalDir;
      try {
        externalDir = Directory('/storage/emulated/0/Documents');
        if (!await externalDir.exists()) {
          externalDir = Directory('/storage/emulated/0/Download');
        }
      } catch (e) {
        externalDir = await getExternalStorageDirectory();
      }

      if (externalDir == null) {
        throw Exception('Could not access external storage');
      }

      final yupireadDir = Directory('${externalDir.path}/Yupiread');
      if (!await yupireadDir.exists()) {
        await yupireadDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'images_to_pdf_$timestamp.pdf';
      final savePath = '${yupireadDir.path}/$fileName';

      // Copy the converted PDF to the save location
      final sourceFile = File(_convertedFilePath!);
      await sourceFile.copy(savePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: ${yupireadDir.path}/$fileName'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 5),
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
      _convertedFilePath = null;
      _temporaryFiles.clear();
      _selectedItems.clear();
      _isSelectMode = false;
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedItems.contains(id)) {
        _selectedItems.remove(id);
      } else {
        _selectedItems.add(id);
      }
    });
  }

  void _toggleTempFileSelection(String fileName) {
    setState(() {
      final tempId = 'temp_$fileName';
      if (_selectedItems.contains(tempId)) {
        _selectedItems.remove(tempId);
      } else {
        _selectedItems.add(tempId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      for (final photo in _photos) {
        if (!_selectedItems.contains(photo.id)) {
          _selectedItems.add(photo.id);
        }
      }
      for (final file in _temporaryFiles) {
        final tempId = 'temp_${file.name}';
        if (!_selectedItems.contains(tempId)) {
          _selectedItems.add(tempId);
        }
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedItems.clear();
    });
  }

  Future<void> _convertSelectedImages() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final pdf = pw.Document();

      // Process selected photos from app
      for (final itemId in _selectedItems) {
        if (!itemId.startsWith('temp_')) {
          // Handle photo from gallery
          final photoId = itemId;
          final photo = _photos.firstWhere((p) => p.id == photoId);
          final imageFile = File(photo.imagePath);
          final imageBytes = await imageFile.readAsBytes();

          pdf.addPage(
            pw.Page(
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(imageBytes),
                  ),
                );
              },
            ),
          );
        } else {
          // Handle temporary file
          final fileName = itemId.substring(5); // Remove 'temp_' prefix
          final tempFile = _temporaryFiles.firstWhere((f) => f.name == fileName);
          if (tempFile.path != null) {
            final imageFile = File(tempFile.path!);
            final imageBytes = await imageFile.readAsBytes();

            pdf.addPage(
              pw.Page(
                build: (pw.Context context) {
                  return pw.Center(
                    child: pw.Image(
                      pw.MemoryImage(imageBytes),
                    ),
                  );
                },
              ),
            );
          }
        }
      }

      // Save PDF to temporary location only (not external storage)
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = '${tempDir.path}/images_to_pdf_$timestamp.pdf';

      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(await pdf.save());

      setState(() {
        _isProcessing = false;
        _isProcessingComplete = true;
        _convertedFilePath = tempPath;
        _selectedItems.clear();
        _isSelectMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Images converted to PDF successfully'),
            backgroundColor: Color(0xFF10B981),
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
            content: Text('Conversion failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
