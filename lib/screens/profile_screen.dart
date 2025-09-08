import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../services/data_service.dart';
import '../services/theme_service.dart' as theme_service;
import '../widgets/theme_selection_dialog.dart';
import 'tag_settings_screen.dart';
import 'gallery_settings_screen.dart';
import 'ebook_settings_screen.dart';
import '../screens/activity_settings_screen.dart';
import '../screens/backup_screen.dart';
import '../widgets/language_selection_dialog.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DataService _dataService = DataService.instance;
  final ImagePicker _picker = ImagePicker();
  late theme_service.ThemeService _themeService;
  final LanguageService _languageService = LanguageService.instance;
  bool _isManagementExpanded = false;
  bool _isAppSettingExpanded = false;
  bool _isDevelopmentExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeThemeService();
  }

  void _initializeThemeService() async {
    _themeService = theme_service.ThemeService.instance;
    if (!_themeService.isInitialized) {
      await _themeService.initialize();
    }
    _themeService.addListener(_onThemeChanged);
    setState(() {});
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.myProfile,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.headlineMedium?.color,
            fontSize: 18,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).cardTheme.shadowColor ??
                        Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Avatar
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                    ),
                    child:
                        _dataService.profileImagePath != null
                            ? ClipOval(
                              child: Image.file(
                                File(_dataService.profileImagePath!),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultAvatar();
                                },
                              ),
                            )
                            : _buildDefaultAvatar(),
                  ),
                  const SizedBox(height: 24),
                  // Username with Edit Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _dataService.username,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showEditProfileDialog,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Management Settings Section
            _buildSettingsCategory(
              title: AppLocalizations.of(context).managementSetting,
              icon: Icons.settings,
              isExpanded: _isManagementExpanded,
              onToggle:
                  () => setState(
                    () => _isManagementExpanded = !_isManagementExpanded,
                  ),
              children: [
                _buildSettingItem(
                  icon: Icons.local_offer,
                  title: AppLocalizations.of(context).tagSetting,
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TagSettingsScreen(),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingItem(
                  icon: Icons.photo_library,
                  title: AppLocalizations.of(context).gallerySetting,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GallerySettingsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingItem(
                  icon: Icons.menu_book,
                  title: AppLocalizations.of(context).ebookSetting,
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EbookSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // App Settings Section
            _buildSettingsCategory(
              title: AppLocalizations.of(context).appSetting,
              icon: Icons.tune,
              isExpanded: _isAppSettingExpanded,
              onToggle:
                  () => setState(
                    () => _isAppSettingExpanded = !_isAppSettingExpanded,
                  ),
              children: [
                _buildSettingItem(
                  icon: Icons.language,
                  title: AppLocalizations.of(context).languageSettingsProfile,
                  color: const Color(0xFF10B981),
                  onTap: () => _showLanguageDialog(),
                ),
                const SizedBox(height: 12),
                _buildSettingItem(
                  icon: _themeService.themeModeIcon,
                  title: AppLocalizations.of(context).themeSetting,
                  color: const Color(0xFF6366F1),
                  onTap: _showThemeSelectionDialog,
                ),
                const SizedBox(height: 12),
                _buildSettingItem(
                  icon: Icons.history,
                  title: AppLocalizations.of(context).activitySettingsProfile,
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActivitySettingsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingItem(
                  icon: Icons.build,
                  title: l10n.toolsSettings,
                  color: const Color(0xFF8B5CF6),
                  onTap: _showToolsSettingDialog,
                ),
                const SizedBox(height: 12),
                _buildSettingItem(
                  icon: Icons.backup,
                  title: 'Backup & Restore',
                  color: const Color(0xFF06B6D4),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BackupScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingItem(
                  icon: Icons.delete_forever,
                  title: AppLocalizations.of(context).removeData,
                  color: const Color(0xFFEF4444),
                  onTap: _showRemoveDataDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Development Settings Section
            _buildSettingsCategory(
              title: l10n.development,
              icon: Icons.code,
              isExpanded: _isDevelopmentExpanded,
              onToggle:
                  () => setState(
                    () => _isDevelopmentExpanded = !_isDevelopmentExpanded,
                  ),
              children: [
                _buildSettingItem(
                  icon: Icons.favorite,
                  title: l10n.supportDevelopment,
                  color: const Color(0xFFEF4444),
                  onTap: () => _launchUrl('https://trakteer.id/euphyfve/tip'),
                ),
                const SizedBox(height: 12),
                _buildSettingItem(
                  icon: Icons.code_rounded,
                  title: l10n.githubRepository,
                  color: const Color(0xFF374151),
                  onTap: () => _launchUrl('https://github.com/Alpinnnn/yupiread'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCategory({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).cardTheme.shadowColor ??
                Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(children: children),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      ),
      child: Icon(
        Icons.person,
        size: 60,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showEditProfileDialog() {
    final TextEditingController usernameController = TextEditingController(
      text: _dataService.username,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              AppLocalizations.of(context).editProfile,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).username,
                    border: const OutlineInputBorder(),
                    counterText: '',
                    helperText: AppLocalizations.of(context).maxCharacters,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            () => _changeProfilePhoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: Text(AppLocalizations.of(context).cameraOption),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            () => _changeProfilePhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: Text(AppLocalizations.of(context).galleryOption),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newUsername = usernameController.text.trim();
                  if (newUsername.isNotEmpty && newUsername.length <= 100) {
                    await _dataService.updateProfile(username: newUsername);
                    setState(() {});
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context).profileUpdated),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  } else if (newUsername.length > 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context).usernameMaxError,
                        ),
                        backgroundColor: Color(0xFFEF4444),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context).save),
              ),
            ],
          ),
    );
  }

  void _changeProfilePhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        // Crop the image before saving
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 85,
          maxWidth: 512,
          maxHeight: 512,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: AppLocalizations.of(context).cropProfilePhoto,
              toolbarColor: Theme.of(context).colorScheme.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              aspectRatioPresets: [CropAspectRatioPreset.square],
            ),
          ],
        );

        if (croppedFile != null) {
          final savedPath = await _dataService.savePhotoFile(croppedFile.path);
          await _dataService.updateProfile(profileImagePath: savedPath);
          setState(() {});
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).profilePhotoUpdatedSuccess),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).failedToUpdateProfilePhoto}: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => LanguageSelectionDialog(
        currentLanguage: _languageService.currentLanguage,
        onLanguageChanged: (language) {
          _languageService.setLanguage(language);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).languageChangedSuccess),
              duration: const Duration(seconds: 2),
            ),
          );
          _showRestartDialog();
        },
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context).languageChangedTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context).restartAppRequired,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(AppLocalizations.of(context).ok),
          ),
        ],
      ),
    );
  }

  void _showThemeSelectionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => ThemeSelectionDialog(
            currentTheme: _themeService.themeMode,
            onThemeChanged: (theme_service.ThemeMode newTheme) async {
              await _themeService.setThemeMode(newTheme);
              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppLocalizations.of(context).themeChangedTo} ${_themeService.getThemeModeString(context)}',
                  ),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
          ),
    );
  }

  void _showToolsSettingDialog() {
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n.toolsSettings,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text(l10n.alwaysShowToolSection),
              subtitle: Text(l10n.toolsSectionDesc),
              value: _dataService.showToolsSection,
              onChanged: (bool value) async {
                await _dataService.setShowToolsSection(value);
                setState(() {});
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value 
                        ? AppLocalizations.of(context).toolsSectionEnabled
                        : AppLocalizations.of(context).toolsSectionDisabled,
                    ),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }


  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka link: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showRemoveDataDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: const Color(0xFFEF4444), size: 24),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context).removeAllData,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Text(
              AppLocalizations.of(context).removeDataConfirmation,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _removeAllData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context).removeAll),
              ),
            ],
          ),
    );
  }

  Future<void> _removeAllData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(AppLocalizations.of(context).removingData),
                ],
              ),
            ),
      );

      // Clear all data
      await _dataService.removeAllData();

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).allDataRemoved),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      // Refresh the UI
      setState(() {});
    } catch (e) {
      // Close loading dialog if still open
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).failedToRemoveData}: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }
}
