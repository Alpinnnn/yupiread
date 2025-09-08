import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../l10n/app_localizations.dart';

class TagSettingsScreen extends StatefulWidget {
  const TagSettingsScreen({super.key});

  @override
  State<TagSettingsScreen> createState() => _TagSettingsScreenState();
}

class _TagSettingsScreenState extends State<TagSettingsScreen> {
  final DataService _dataService = DataService.instance;
  final TextEditingController _tagController = TextEditingController();
  String? _selectedTagForDeletion;

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).tagSettings,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Tag Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).cardTheme.shadowColor ?? Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).addNewTag,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.headlineSmall?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            hintText: 'Masukkan nama tag...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _addTag,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).addTag,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Tags List Section
            Text(
              AppLocalizations.of(context).tagList,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).cardTheme.shadowColor ?? Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Available Tags Section
                    Text(
                      AppLocalizations.of(context).availableTags,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _dataService.availableTags.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.label_outline,
                                    size: 48,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLocalizations.of(context).noTagsAvailable,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context).addTagsToOrganize,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _dataService.availableTags
                                  .map((tag) => _buildUnifiedTagChip(tag))
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedTagChip(String tag) {
    final isDefaultTag = ['Catatan', 'Penting', 'Tugas', 'Ide', 'Referensi'].contains(tag);
    final isSelected = _selectedTagForDeletion == tag;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTagForDeletion = isSelected ? null : tag;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.label,
              size: 16,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            const SizedBox(width: 6),
            Text(
              tag,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            if (isSelected && !isDefaultTag) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showDeleteConfirmation(tag),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            if (isSelected && isDefaultTag) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock,
                  size: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addTag() async {
    final tagName = _tagController.text.trim();
    if (tagName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).tagNameEmpty),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final success = await _dataService.addCustomTag(tagName);
    if (success) {
      _tagController.clear();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).tagAddedSuccessfully(tagName)),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).tagAlreadyExists(tagName)),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _showDeleteConfirmation(String tag) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              AppLocalizations.of(context).deleteTag,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            content: Text(AppLocalizations.of(context).confirmDeleteTag(tag)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  final success = await _dataService.removeCustomTag(tag);
                  Navigator.pop(context);

                  if (success) {
                    setState(() {
                      _selectedTagForDeletion = null; // Clear selection after deletion
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context).tagDeletedSuccessfully(tag)),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context).failedToDeleteTag),
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context).delete),
              ),
            ],
          ),
    );
  }
}
