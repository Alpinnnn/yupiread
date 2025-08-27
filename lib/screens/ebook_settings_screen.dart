import 'package:flutter/material.dart';
import '../models/ebook_model.dart';
import '../services/data_service.dart';
import 'ebook_reader_screen.dart';

class EbookSettingsScreen extends StatefulWidget {
  const EbookSettingsScreen({super.key});

  @override
  State<EbookSettingsScreen> createState() => _EbookSettingsScreenState();
}

class _EbookSettingsScreenState extends State<EbookSettingsScreen> {
  final DataService _dataService = DataService.instance;
  List<EbookModel> _ebooks = [];
  Set<String> _selectedEbookIds = {};
  bool _isSelectMode = false;

  @override
  void initState() {
    super.initState();
    _loadEbooks();
  }

  void _loadEbooks() {
    setState(() {
      _ebooks = _dataService.ebooks;
    });
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) {
        _selectedEbookIds.clear();
      }
    });
  }

  void _toggleEbookSelection(String ebookId) {
    setState(() {
      if (_selectedEbookIds.contains(ebookId)) {
        _selectedEbookIds.remove(ebookId);
      } else {
        _selectedEbookIds.add(ebookId);
      }
    });
  }

  void _selectAllEbooks() {
    setState(() {
      if (_selectedEbookIds.length == _ebooks.length) {
        _selectedEbookIds.clear();
      } else {
        _selectedEbookIds = _ebooks.map((e) => e.id).toSet();
      }
    });
  }

  void _showEbookOptions(EbookModel ebook) {
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
              ebook.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.play_arrow,
              title: 'Baca',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EbookReaderScreen(ebookId: ebook.id),
                  ),
                ).then((_) => _loadEbooks());
              },
            ),
            _buildOptionTile(
              icon: Icons.select_all,
              title: 'Pilih untuk hapus',
              subtitle: 'Pilih ebook ini untuk dihapus bersamaan',
              onTap: () {
                Navigator.pop(context);
                _toggleSelectMode();
                _selectedEbookIds.add(ebook.id);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete,
              title: 'Hapus',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation([ebook.id]);
              },
            ),
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

  void _showDeleteConfirmation(List<String> ebookIds) {
    final totalItems = ebookIds.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Ebook'),
        content: Text('Apakah Anda yakin ingin menghapus $totalItems ebook?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedEbooks(ebookIds);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _deleteSelectedEbooks(List<String> ebookIds) {
    for (String ebookId in ebookIds) {
      _dataService.deleteEbook(ebookId);
    }
    _loadEbooks();
    _toggleSelectMode();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${ebookIds.length} ebook berhasil dihapus'),
        backgroundColor: Colors.green,
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return 4; // 4 columns for very wide screens
    } else if (screenWidth > 800) {
      return 3; // 3 columns for wide screens
    } else {
      return 2; // 2 columns for mobile/tablet
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _ebooks.length;
    final selectedCount = _selectedEbookIds.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isSelectMode ? '$selectedCount dipilih' : 'Ebook Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontSize: 18,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        actions: _isSelectMode
            ? [
                if (selectedCount > 0)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(
                      _selectedEbookIds.toList(),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    _selectedEbookIds.length == _ebooks.length 
                        ? Icons.deselect 
                        : Icons.select_all,
                  ),
                  onPressed: _selectAllEbooks,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleSelectMode,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _toggleSelectMode,
                ),
              ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$totalItems ebook tersimpan',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: totalItems == 0
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.library_books_outlined,
                              size: 64,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada ebook tersimpan',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getCrossAxisCount(context),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: totalItems,
                        itemBuilder: (context, index) {
                          return _buildEbookCard(_ebooks[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEbookCard(EbookModel ebook) {
    final isSelected = _selectedEbookIds.contains(ebook.id);
    
    final categoryColors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF06B6D4),
    ];

    final colorIndex = ebook.id.hashCode % categoryColors.length;
    final categoryColor = categoryColors[colorIndex.abs()];

    return GestureDetector(
      onTap: () {
        if (_isSelectMode) {
          _toggleEbookSelection(ebook.id);
        } else {
          _showEbookOptions(ebook);
        }
      },
      onLongPress: () {
        if (!_isSelectMode) {
          _toggleSelectMode();
          _selectedEbookIds.add(ebook.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).cardTheme.shadowColor ?? Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [categoryColor, categoryColor.withOpacity(0.7)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white.withOpacity(0.8),
                            size: 48,
                          ),
                        ),
                        if (ebook.tags.isNotEmpty)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ebook.tags.first,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ebook.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ebook.totalPages} halaman',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: ebook.progress,
                        backgroundColor: Theme.of(context).brightness == Brightness.dark 
                            ? Theme.of(context).cardTheme.color?.withOpacity(0.3) ?? Colors.grey[800]
                            : Theme.of(context).colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                        minHeight: 3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ebook.progressPercentage} selesai',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isSelectMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardTheme.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
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
              ),
          ],
        ),
      ),
    );
  }
}
