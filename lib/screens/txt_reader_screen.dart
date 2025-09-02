import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ebook_model.dart';
import '../services/data_service.dart';
import '../l10n/app_localizations.dart';

class TxtReaderScreen extends StatefulWidget {
  final String ebookId;

  const TxtReaderScreen({
    super.key,
    required this.ebookId,
  });

  @override
  State<TxtReaderScreen> createState() => _TxtReaderScreenState();
}

class _TxtReaderScreenState extends State<TxtReaderScreen> {
  final DataService _dataService = DataService.instance;
  EbookModel? _ebook;
  String _content = '';
  bool _isLoading = true;
  String _error = '';
  final ScrollController _scrollController = ScrollController();
  double _fontSize = 16.0;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadEbook();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadEbook() async {
    try {
      final ebook = _dataService.ebooks.firstWhere(
        (e) => e.id == widget.ebookId,
        orElse: () => throw Exception('Ebook not found'),
      );

      final file = File(ebook.filePath);
      if (!await file.exists()) {
        setState(() {
          _error = AppLocalizations.of(context).fileNotFound;
          _isLoading = false;
        });
        return;
      }

      final content = await file.readAsString();
      
      setState(() {
        _ebook = ebook;
        _content = content;
        _isLoading = false;
      });

      // Update reading progress
      await _dataService.updateEbookProgress(widget.ebookId, 1);
    } catch (e) {
      setState(() {
        _error = '${AppLocalizations.of(context).readingFailed}$e';
        _isLoading = false;
      });
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).readerSettings,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(AppLocalizations.of(context).fontSize),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 12.0,
                    max: 24.0,
                    divisions: 12,
                    label: _fontSize.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _fontSize = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            SwitchListTile(
              title: Text(AppLocalizations.of(context).darkMode),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).close),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).textCopiedToClipboard),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(_ebook?.title ?? AppLocalizations.of(context).textReader),
        backgroundColor: _isDarkMode ? Colors.grey[900] : null,
        foregroundColor: _isDarkMode ? Colors.white : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
            tooltip: AppLocalizations.of(context).copyText,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: AppLocalizations.of(context).settings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(AppLocalizations.of(context).back),
                      ),
                    ],
                  ),
                )
              : Container(
                  color: _isDarkMode ? Colors.black : Colors.white,
                  child: Scrollbar(
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        _content,
                        style: TextStyle(
                          fontSize: _fontSize,
                          height: 1.5,
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
