import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
          // Find the best APK download URL based on device architecture
          final assets = releaseData['assets'] as List;
          String? apkUrl = await _findBestApkUrl(assets);
          
          if (apkUrl != null && context.mounted) {
            // Extract release title from tag name (format: "v?.?.? [release title]")
            final releaseTitle = _extractReleaseTitle(releaseData['tag_name'] ?? '');
            
            _showUpdateDialog(
              context,
              currentVersion,
              latestVersion,
              apkUrl,
              releaseTitle.isNotEmpty ? releaseTitle : AppLocalizations.of(context).updateAvailable,
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
    try {
      // Clean version strings to remove any non-numeric characters except dots
      final cleanCurrent = _sanitizeVersionString(current);
      final cleanLatest = _sanitizeVersionString(latest);
      
      final currentParts = cleanCurrent.split('.').map((part) {
        // Extract only numeric part from each segment
        final numericPart = RegExp(r'\d+').firstMatch(part)?.group(0);
        return int.tryParse(numericPart ?? '0') ?? 0;
      }).toList();
      
      final latestParts = cleanLatest.split('.').map((part) {
        // Extract only numeric part from each segment
        final numericPart = RegExp(r'\d+').firstMatch(part)?.group(0);
        return int.tryParse(numericPart ?? '0') ?? 0;
      }).toList();
      
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
    } catch (e) {
      debugPrint('Version comparison error: $e');
      return false;
    }
  }
  
  /// Sanitize version string to handle various formats
  static String _sanitizeVersionString(String version) {
    // Remove common prefixes and suffixes
    String cleaned = version
        .replaceAll(RegExp(r'^v'), '') // Remove 'v' prefix
        .replaceAll(RegExp(r'-release$'), '') // Remove '-release' suffix
        .replaceAll(RegExp(r'-.*$'), ''); // Remove any suffix after dash
    
    return cleaned;
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
  
  /// Extract release title from tag name (format: "v?.?.? [release title]")
  static String _extractReleaseTitle(String tagName) {
    try {
      // Look for pattern like "v1.2.3 [Release Title]"
      final regex = RegExp(r'v\d+\.\d+\.\d+\s*\[(.+)\]');
      final match = regex.firstMatch(tagName);
      if (match != null && match.groupCount >= 1) {
        return match.group(1)?.trim() ?? '';
      }
      return '';
    } catch (e) {
      debugPrint('Failed to extract release title: $e');
      return '';
    }
  }

  /// Find the best APK URL based on device architecture
  static Future<String?> _findBestApkUrl(List assets) async {
    try {
      // Get device architecture
      String? deviceArch = await _getDeviceArchitecture();
      
      // Priority order for APK selection based on architecture
      List<String> apkPriority = [];
      
      if (deviceArch != null) {
        switch (deviceArch.toLowerCase()) {
          case 'arm64':
          case 'aarch64':
            apkPriority = [
              'yupiread-arm64-v8a-release.apk',
              'yupiread-armeabi-v7a-release.apk',
              'yupiread-x86_64-release.apk'
            ];
            break;
          case 'arm':
          case 'armv7':
            apkPriority = [
              'yupiread-armeabi-v7a-release.apk',
              'yupiread-arm64-v8a-release.apk',
              'yupiread-x86_64-release.apk'
            ];
            break;
          case 'x86_64':
          case 'x64':
            apkPriority = [
              'yupiread-x86_64-release.apk',
              'yupiread-arm64-v8a-release.apk',
              'yupiread-armeabi-v7a-release.apk'
            ];
            break;
          default:
            apkPriority = [
              'yupiread-arm64-v8a-release.apk',
              'yupiread-armeabi-v7a-release.apk',
              'yupiread-x86_64-release.apk'
            ];
        }
      } else {
        // Default priority if architecture detection fails
        apkPriority = [
          'yupiread-arm64-v8a-release.apk',
          'yupiread-armeabi-v7a-release.apk',
          'yupiread-x86_64-release.apk'
        ];
      }

      // Find the best matching APK
      for (String preferredApk in apkPriority) {
        for (final asset in assets) {
          final downloadUrl = asset['browser_download_url'] as String;
          if (downloadUrl.toLowerCase().contains(preferredApk.toLowerCase())) {
            return downloadUrl;
          }
        }
      }

      // Fallback: find any APK
      for (final asset in assets) {
        final downloadUrl = asset['browser_download_url'] as String;
        if (downloadUrl.toLowerCase().endsWith('.apk')) {
          return downloadUrl;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Failed to find best APK URL: $e');
      return null;
    }
  }

  /// Get device architecture
  static Future<String?> _getDeviceArchitecture() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        
        // Get supported ABIs (Application Binary Interfaces)
        final supportedAbis = androidInfo.supportedAbis;
        if (supportedAbis.isNotEmpty) {
          final primaryAbi = supportedAbis.first;
          
          // Map ABI to architecture
          switch (primaryAbi.toLowerCase()) {
            case 'arm64-v8a':
              return 'arm64';
            case 'armeabi-v7a':
              return 'arm';
            case 'x86_64':
              return 'x86_64';
            case 'x86':
              return 'x86';
            default:
              return primaryAbi;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get device architecture: $e');
      return null;
    }
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
