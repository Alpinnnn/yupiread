import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  final LanguageService _languageService = LanguageService.instance;
  AppLanguage _selectedLanguage = LanguageService.instance.currentLanguage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.languageSettings),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectLanguage,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.currentLanguage + ': ${_languageService.currentLanguage.displayName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Language options
            ...AppLanguage.values.map((language) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedLanguage == language 
                      ? const Color(0xFF6366F1)
                      : Theme.of(context).dividerColor,
                  width: _selectedLanguage == language ? 2 : 1,
                ),
              ),
              child: RadioListTile<AppLanguage>(
                title: Text(
                  language.displayName,
                  style: TextStyle(
                    fontWeight: _selectedLanguage == language 
                        ? FontWeight.w600 
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  language.code.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                value: language,
                groupValue: _selectedLanguage,
                activeColor: const Color(0xFF6366F1),
                onChanged: (AppLanguage? value) {
                  if (value != null) {
                    setState(() {
                      _selectedLanguage = value;
                    });
                  }
                },
              ),
            )).toList(),
            
            const Spacer(),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedLanguage != _languageService.currentLanguage
                    ? _saveLanguageSettings
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.save,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLanguageSettings() async {
    await _languageService.setLanguage(_selectedLanguage);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).success),
          backgroundColor: Colors.green,
        ),
      );
      
      // Show restart dialog
      _showRestartDialog();
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).languageChanged),
        content: Text(AppLocalizations.of(context).restartAppMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to profile screen
            },
            child: Text(AppLocalizations.of(context).ok),
          ),
        ],
      ),
    );
  }
}
