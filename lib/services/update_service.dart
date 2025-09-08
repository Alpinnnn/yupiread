import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

class UpdateService {
  static const String _githubApiUrl = 'https://api.github.com/repos/Alpinnnn/yupiread/releases/latest';
  
  /// Check for app updates and show dialog if available
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // Fetch latest release from GitHub
      final response = await http.get(Uri.parse(_githubApiUrl));
      
      if (response.statusCode == 200) {
        final releaseData = json.decode(response.body);
        final latestVersion = _cleanVersionString(releaseData['tag_name']);
        
        // Compare versions
        if (_isNewerVersion(currentVersion, latestVersion)) {
          // Find APK download URL
          final assets = releaseData['assets'] as List;
          String? apkUrl;
          
          for (final asset in assets) {
            final downloadUrl = asset['browser_download_url'] as String;
            if (downloadUrl.toLowerCase().endsWith('.apk')) {
              apkUrl = downloadUrl;
              break;
            }
          }
          
          if (apkUrl != null && context.mounted) {
            _showUpdateDialog(
              context,
              currentVersion,
              latestVersion,
              apkUrl,
              releaseData['name'] ?? AppLocalizations.of(context).updateAvailable,
              releaseData['body'] ?? '',
            );
          }
        }
      }
    } catch (e) {
      // Silently fail - don't show error to user for update checks
      debugPrint('Update check failed: $e');
    }
  }
  
  /// Remove 'v' prefix from version string if present
  static String _cleanVersionString(String version) {
    return version.startsWith('v') ? version.substring(1) : version;
  }
  
  /// Compare version strings to determine if new version is available
  static bool _isNewerVersion(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();
    
    // Pad shorter version with zeros
    while (currentParts.length < latestParts.length) {
      currentParts.add(0);
    }
    while (latestParts.length < currentParts.length) {
      latestParts.add(0);
    }
    
    for (int i = 0; i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) {
        return true;
      } else if (latestParts[i] < currentParts[i]) {
        return false;
      }
    }
    
    return false;
  }
  
  /// Show update dialog with options
  static void _showUpdateDialog(
    BuildContext context,
    String currentVersion,
    String latestVersion,
    String downloadUrl,
    String releaseName,
    String releaseNotes,
  ) {
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.system_update,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).updateAvailable,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'v$currentVersion → v$latestVersion',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (releaseName.isNotEmpty && releaseName != AppLocalizations.of(context).updateAvailable)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  releaseName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            if (releaseNotes.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    releaseNotes,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context).updateLater,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _launchDownload(downloadUrl);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.download, size: 18),
            label: Text(AppLocalizations.of(context).updateNow),
          ),
        ],
      ),
    );
  }
  
  /// Launch download URL
  static Future<void> _launchDownload(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Failed to launch download URL: $e');
    }
  }
}
