import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import '../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService.instance;
  List<BackupFileInfo> _backupFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _backupService.addListener(_onBackupServiceChanged);
    _loadBackupFiles();
  }

  @override
  void dispose() {
    _backupService.removeListener(_onBackupServiceChanged);
    super.dispose();
  }

  void _onBackupServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadBackupFiles() async {
    if (!_backupService.isSignedInToGoogleDrive) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final files = await _backupService.getBackupFiles();
      setState(() {
        _backupFiles = files;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToLoadBackups}: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInToGoogleDrive() async {
    final success = await _backupService.signInToGoogleDrive();
    if (success) {
      await _loadBackupFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).signInSuccessful)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).signInFailed)),
        );
      }
    }
  }

  Future<void> _signOutFromGoogleDrive() async {
    await _backupService.signOutFromGoogleDrive();
    setState(() {
      _backupFiles.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).signOutSuccessful)),
      );
    }
  }

  Future<void> _createBackup() async {
    if (!_backupService.isSignedInToGoogleDrive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).pleaseSignInFirst)),
      );
      return;
    }

    final success = await _backupService.backupToGoogleDrive();
    if (success) {
      await _loadBackupFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).backupSuccessful)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).backupFailed}: ${_backupService.backupStatus}')),
        );
      }
    }
  }

  Future<void> _restoreBackup(BackupFileInfo backupFile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).confirmRestore),
        content: Text(
          '${AppLocalizations.of(context).confirmRestoreMessage.replaceAll('backup ini', 'backup "${backupFile.name}"')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).restore),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _backupService.restoreFromGoogleDrive(backupFile.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? AppLocalizations.of(context).restoreSuccessful : '${AppLocalizations.of(context).restoreFailed}: ${_backupService.restoreStatus}'),
          ),
        );
      }
    }
  }

  Future<void> _deleteBackup(BackupFileInfo backupFile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteBackup),
        content: Text(AppLocalizations.of(context).confirmDeleteBackup.replaceAll('backup ini', 'backup "${backupFile.name}"')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _backupService.deleteBackupFile(backupFile.id);
      if (success) {
        await _loadBackupFiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).backupDeleted)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).failedToDeleteBackup)),
          );
        }
      }
    }
  }

  Future<void> _showAutoBackupDialog() async {
    final prefs = await SharedPreferences.getInstance();
    bool isAutoBackupEnabled = prefs.getBool('auto_backup_enabled') ?? false;
    String currentInterval = prefs.getString('auto_backup_interval') ?? 'weekly';

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AutoBackupDialog(
        isEnabled: isAutoBackupEnabled,
        currentInterval: currentInterval,
      ),
    );

    if (result != null) {
      await prefs.setBool('auto_backup_enabled', result['enabled']);
      await prefs.setString('auto_backup_interval', result['interval']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['enabled'] 
              ? AppLocalizations.of(context).autoBackupEnabled 
              : AppLocalizations.of(context).autoBackupDisabled),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).backupRestore),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAutoBackupDialog,
            icon: const Icon(Icons.schedule),
            tooltip: AppLocalizations.of(context).autoBackup,
          ),
        ],
      ),
      body: Column(
        children: [
          // Google Drive Status Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cloud,
                      color: _backupService.isSignedInToGoogleDrive 
                          ? Colors.green 
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).googleDrive,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_backupService.isSignedInToGoogleDrive) ...[
                  Text(
                    '${AppLocalizations.of(context).connectedAs}: ${_backupService.currentUserEmail}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _backupService.isBackingUp ? null : _createBackup,
                          icon: _backupService.isBackingUp 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.backup),
                          label: Text(_backupService.isBackingUp ? AppLocalizations.of(context).backingUp : AppLocalizations.of(context).createBackup),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _signOutFromGoogleDrive,
                        child: Text(AppLocalizations.of(context).signOut),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    AppLocalizations.of(context).notConnectedToGoogleDrive,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _signInToGoogleDrive,
                      icon: const Icon(Icons.login),
                      label: Text(AppLocalizations.of(context).signInToGoogleDrive),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Backup Progress
          if (_backupService.isBackingUp || _backupService.isRestoring) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _backupService.isBackingUp 
                        ? _backupService.backupStatus 
                        : _backupService.restoreStatus,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _backupService.isBackingUp 
                        ? _backupService.backupProgress 
                        : _backupService.restoreProgress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Backup Files List
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context).backupList,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_backupService.isSignedInToGoogleDrive)
                          IconButton(
                            onPressed: _isLoading ? null : _loadBackupFiles,
                            icon: _isLoading 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _buildBackupFilesList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBackupFilesList() {
    if (!_backupService.isSignedInToGoogleDrive) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).signInToViewBackups,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_backupFiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.backup, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                '${AppLocalizations.of(context).noBackupsYet}\n${AppLocalizations.of(context).createFirstBackup}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _backupFiles.length,
      itemBuilder: (context, index) {
        final backupFile = _backupFiles[index];
        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.archive),
          ),
          title: Text(
            backupFile.name.replaceAll('yupiread_backup_', '').replaceAll('.zip', ''),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '${backupFile.formattedSize} • ${backupFile.formattedDate}',
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'restore':
                  _restoreBackup(backupFile);
                  break;
                case 'delete':
                  _deleteBackup(backupFile);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'restore',
                child: Row(
                  children: [
                    const Icon(Icons.restore),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).restore),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).delete, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AutoBackupDialog extends StatefulWidget {
  final bool isEnabled;
  final String currentInterval;

  const _AutoBackupDialog({
    required this.isEnabled,
    required this.currentInterval,
  });

  @override
  State<_AutoBackupDialog> createState() => _AutoBackupDialogState();
}

class _AutoBackupDialogState extends State<_AutoBackupDialog> {
  late bool _isEnabled;
  late String _selectedInterval;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.isEnabled;
    _selectedInterval = widget.currentInterval;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).autoBackup),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(AppLocalizations.of(context).enableAutoBackup),
            value: _isEnabled,
            onChanged: (value) {
              setState(() {
                _isEnabled = value;
              });
            },
          ),
          if (_isEnabled) ...[
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).selectInterval,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: Text(AppLocalizations.of(context).daily),
              value: 'daily',
              groupValue: _selectedInterval,
              onChanged: (value) {
                setState(() {
                  _selectedInterval = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: Text(AppLocalizations.of(context).weekly),
              value: 'weekly',
              groupValue: _selectedInterval,
              onChanged: (value) {
                setState(() {
                  _selectedInterval = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: Text(AppLocalizations.of(context).monthly),
              value: 'monthly',
              groupValue: _selectedInterval,
              onChanged: (value) {
                setState(() {
                  _selectedInterval = value!;
                });
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop({
              'enabled': _isEnabled,
              'interval': _selectedInterval,
            });
          },
          child: Text(AppLocalizations.of(context).save),
        ),
      ],
    );
  }
}
