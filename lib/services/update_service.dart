import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../l10n/app_localizations.dart';

class UpdateService {
  static const String _githubApiUrl = 'https://api.github.com/repos/Alpinnnn/yupiread/releases';
  
  /// Check for app updates and show dialog if available
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      debugPrint('Update check: Current version = $currentVersion');
      
      // Fetch all releases from GitHub (including pre-releases)
      final response = await http.get(Uri.parse(_githubApiUrl));
      
      if (response.statusCode == 200) {
        final releasesData = json.decode(response.body) as List;
        
        debugPrint('Update check: Found ${releasesData.length} releases');
        
        if (releasesData.isNotEmpty) {
          // Find the latest release (including pre-releases)
          final latestRelease = _findLatestRelease(releasesData);
          
          if (latestRelease != null) {
            final latestVersion = _cleanVersionString(latestRelease['tag_name']);
            final isPrerelease = latestRelease['prerelease'] ?? false;
            
            debugPrint('Update check: Latest version = $latestVersion (prerelease: $isPrerelease)');
            
            // Compare versions - only show update if latest is actually newer
            final isNewer = _isNewerVersion(currentVersion, latestVersion);
            debugPrint('Update check: Is newer version? $isNewer');
            
            if (isNewer) {
              debugPrint('Update check: New version available!');
              
              // Double-check: ensure we're not showing update for same or older version
              final cleanCurrent = _sanitizeVersionString(currentVersion);
              final cleanLatest = _sanitizeVersionString(latestVersion);
              
              if (cleanCurrent == cleanLatest) {
                debugPrint('Update check: Versions are identical after sanitization - skipping update');
                return;
              }
              
              // Find the best APK download URL based on device architecture
              final assets = latestRelease['assets'] as List;
              String? apkUrl = await _findBestApkUrl(assets, isPrerelease);
              
              debugPrint('Update check: APK URL = $apkUrl');
              
              if (apkUrl != null && context.mounted) {
                // Extract release title from tag name or use release name
                final extractedTitle = _extractReleaseTitle(latestRelease['tag_name'] ?? '');
                final releaseTitle = extractedTitle.isNotEmpty ? extractedTitle : (latestRelease['name'] ?? '');
                
                _showUpdateDialog(
                  context,
                  currentVersion,
                  latestVersion,
                  apkUrl,
                  releaseTitle.isNotEmpty ? releaseTitle : AppLocalizations.of(context).updateAvailable,
                  latestRelease['body'] ?? '',
                );
              } else {
                debugPrint('Update check: No compatible APK found or context not mounted');
              }
            } else {
              debugPrint('Update check: No newer version available (current: $currentVersion, latest: $latestVersion)');
            }
          } else {
            debugPrint('Update check: No latest release found');
          }
        } else {
          debugPrint('Update check: No releases found');
        }
      } else {
        debugPrint('Update check: HTTP error ${response.statusCode}');
      }
    } catch (e) {
      // Silently fail - don't show error to user for update checks
      debugPrint('Update check failed: $e');
    }
  }
  
  /// Find the latest release from the releases list (including pre-releases)
  static Map<String, dynamic>? _findLatestRelease(List releasesData) {
    try {
      if (releasesData.isEmpty) return null;
      
      // Sort releases by published_at date (most recent first)
      releasesData.sort((a, b) {
        final dateA = DateTime.parse(a['published_at'] ?? a['created_at'] ?? '');
        final dateB = DateTime.parse(b['published_at'] ?? b['created_at'] ?? '');
        return dateB.compareTo(dateA); // Descending order (newest first)
      });
      
      // Return the most recent release (could be stable or pre-release)
      return releasesData.first as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error finding latest release: $e');
      return null;
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
      
      debugPrint('Version comparison: current="$current" -> "$cleanCurrent", latest="$latest" -> "$cleanLatest"');
      
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
      
      debugPrint('Version parts: current=$currentParts, latest=$latestParts');
      
      // Compare version parts
      for (int i = 0; i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) {
          debugPrint('Latest version is newer: ${latestParts[i]} > ${currentParts[i]} at index $i');
          return true;
        } else if (latestParts[i] < currentParts[i]) {
          debugPrint('Current version is newer: ${currentParts[i]} > ${latestParts[i]} at index $i');
          return false;
        }
      }
      
      // Versions are equal
      debugPrint('Versions are equal - no update needed');
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
        .replaceAll(RegExp(r'-beta$'), '') // Remove '-beta' suffix
        .replaceAll(RegExp(r'-alpha$'), '') // Remove '-alpha' suffix
        .replaceAll(RegExp(r'-rc\d*$'), '') // Remove '-rc' or '-rc1' suffix
        .replaceAll(RegExp(r'-dev$'), '') // Remove '-dev' suffix
        .replaceAll(RegExp(r'-debug$'), '') // Remove '-debug' suffix
        .replaceAll(RegExp(r'\+.*$'), '') // Remove build metadata after '+'
        .replaceAll(RegExp(r'-.*$'), ''); // Remove any remaining suffix after dash
    
    // Ensure we have at least a basic version format
    if (!RegExp(r'^\d+(\.\d+)*$').hasMatch(cleaned)) {
      // If sanitization resulted in invalid format, try to extract just numbers and dots
      final matches = RegExp(r'\d+(\.\d+)*').firstMatch(version);
      if (matches != null) {
        cleaned = matches.group(0) ?? '0.0.0';
      } else {
        cleaned = '0.0.0'; // Fallback for completely invalid versions
      }
    }
    
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
  static Future<String?> _findBestApkUrl(List assets, [bool isPrerelease = false]) async {
    try {
      // Get device architecture
      String? deviceArch = await _getDeviceArchitecture();
      
      // Determine APK suffix based on release type
      final apkSuffix = isPrerelease ? 'beta.apk' : 'release.apk';
      
      // Priority order for APK selection based on architecture
      List<String> apkPriority = [];
      
      if (deviceArch != null) {
        switch (deviceArch.toLowerCase()) {
          case 'arm64':
          case 'aarch64':
            apkPriority = [
              'yupiread-arm64-v8a-$apkSuffix',
              'yupiread-armeabi-v7a-$apkSuffix',
              'yupiread-x86_64-$apkSuffix'
            ];
            break;
          case 'arm':
          case 'armv7':
            apkPriority = [
              'yupiread-armeabi-v7a-$apkSuffix',
              'yupiread-arm64-v8a-$apkSuffix',
              'yupiread-x86_64-$apkSuffix'
            ];
            break;
          case 'x86_64':
          case 'x64':
            apkPriority = [
              'yupiread-x86_64-$apkSuffix',
              'yupiread-arm64-v8a-$apkSuffix',
              'yupiread-armeabi-v7a-$apkSuffix'
            ];
            break;
          default:
            apkPriority = [
              'yupiread-arm64-v8a-$apkSuffix',
              'yupiread-armeabi-v7a-$apkSuffix',
              'yupiread-x86_64-$apkSuffix'
            ];
        }
      } else {
        // Default priority if architecture detection fails
        apkPriority = [
          'yupiread-arm64-v8a-$apkSuffix',
          'yupiread-armeabi-v7a-$apkSuffix',
          'yupiread-x86_64-$apkSuffix'
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

      // Fallback 1: Try alternative suffix if primary search failed
      final alternativeSuffix = isPrerelease ? 'release.apk' : 'beta.apk';
      final alternativeApkPriority = apkPriority.map((apk) => 
        apk.replaceAll(apkSuffix, alternativeSuffix)
      ).toList();
      
      for (String preferredApk in alternativeApkPriority) {
        for (final asset in assets) {
          final downloadUrl = asset['browser_download_url'] as String;
          if (downloadUrl.toLowerCase().contains(preferredApk.toLowerCase())) {
            return downloadUrl;
          }
        }
      }

      // Fallback 2: Find any APK with architecture preference
      if (deviceArch != null) {
        final archPatterns = ['arm64-v8a', 'armeabi-v7a', 'x86_64'];
        for (String archPattern in archPatterns) {
          for (final asset in assets) {
            final downloadUrl = asset['browser_download_url'] as String;
            if (downloadUrl.toLowerCase().contains(archPattern) && 
                downloadUrl.toLowerCase().endsWith('.apk')) {
              return downloadUrl;
            }
          }
        }
      }

      // Fallback 3: Find any APK
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

  /// Launch download URL with multiple fallback options
  static Future<void> _launchDownload(String url) async {
    try {
      final uri = Uri.parse(url);
      debugPrint('Attempting to launch download URL: $url');
      
      // For Android, try platform-specific method first
      if (Platform.isAndroid) {
        final success = await _launchDownloadAndroid(url);
        if (success) {
          debugPrint('Successfully launched via Android Intent');
          return;
        }
      }
      
      // Try different launch modes in order of preference
      final launchModes = [
        LaunchMode.externalApplication,
        LaunchMode.platformDefault,
        LaunchMode.externalNonBrowserApplication,
      ];
      
      for (final mode in launchModes) {
        try {
          debugPrint('Trying launch mode: $mode');
          
          if (await canLaunchUrl(uri)) {
            final success = await launchUrl(uri, mode: mode);
            if (success) {
              debugPrint('Successfully launched with mode: $mode');
              return;
            }
          }
        } catch (e) {
          debugPrint('Launch mode $mode failed: $e');
          continue;
        }
      }
      
      // Fallback: try to open GitHub releases page instead of direct download
      try {
        debugPrint('Direct download failed, trying GitHub releases page');
        final releasesPageUrl = 'https://github.com/Alpinnnn/yupiread/releases';
        final releasesUri = Uri.parse(releasesPageUrl);
        
        if (await canLaunchUrl(releasesUri)) {
          await launchUrl(releasesUri, mode: LaunchMode.externalApplication);
          debugPrint('Successfully opened GitHub releases page');
          return;
        }
      } catch (e) {
        debugPrint('GitHub releases page fallback failed: $e');
      }
      
      // Final fallback: try to open in browser
      try {
        debugPrint('All external launches failed, trying in-app browser');
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (e) {
        debugPrint('Browser fallback also failed: $e');
        
        // Last resort: try with webViewConfiguration
        try {
          await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
              enableDomStorage: true,
            ),
          );
        } catch (e) {
          debugPrint('All launch attempts failed: $e');
        }
      }
      
    } catch (e) {
      debugPrint('Failed to parse or launch download URL: $e');
    }
  }

  /// Android-specific download launch using platform channel
  static Future<bool> _launchDownloadAndroid(String url) async {
    try {
      const platform = MethodChannel('com.alpinnnn.yupiread/download');
      
      final result = await platform.invokeMethod('launchDownload', {
        'url': url,
      });
      
      return result == true;
    } catch (e) {
      debugPrint('Android platform channel failed: $e');
      return false;
    }
  }
}
