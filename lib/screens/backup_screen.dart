import 'package:flutter/material.dart';
import '../services/backup_service.dart';

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
          SnackBar(content: Text('Gagal memuat daftar backup: $e')),
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
          const SnackBar(content: Text('Berhasil masuk ke Google Drive')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal masuk ke Google Drive')),
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
        const SnackBar(content: Text('Berhasil keluar dari Google Drive')),
      );
    }
  }

  Future<void> _createBackup() async {
    if (!_backupService.isSignedInToGoogleDrive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masuk ke Google Drive terlebih dahulu')),
      );
      return;
    }

    final success = await _backupService.backupToGoogleDrive();
    if (success) {
      await _loadBackupFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup berhasil dibuat')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup gagal: ${_backupService.backupStatus}')),
        );
      }
    }
  }

  Future<void> _restoreBackup(BackupFileInfo backupFile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Restore'),
        content: Text(
          'Apakah Anda yakin ingin mengembalikan data dari backup "${backupFile.name}"?\n\n'
          'Semua data saat ini akan diganti dengan data dari backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _backupService.restoreFromGoogleDrive(backupFile.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Restore berhasil' : 'Restore gagal: ${_backupService.restoreStatus}'),
          ),
        );
      }
    }
  }

  Future<void> _deleteBackup(BackupFileInfo backupFile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Backup'),
        content: Text('Apakah Anda yakin ingin menghapus backup "${backupFile.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
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
            const SnackBar(content: Text('Backup berhasil dihapus')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus backup')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        elevation: 0,
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
                      'Google Drive',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_backupService.isSignedInToGoogleDrive) ...[
                  Text(
                    'Terhubung sebagai: ${_backupService.currentUserEmail}',
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
                          label: Text(_backupService.isBackingUp ? 'Backup...' : 'Buat Backup'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _signOutFromGoogleDrive,
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'Belum terhubung ke Google Drive',
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
                      label: const Text('Masuk ke Google Drive'),
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
                          'Daftar Backup',
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Masuk ke Google Drive untuk melihat backup',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.backup, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Belum ada backup\nBuat backup pertama Anda',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
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
              const PopupMenuItem(
                value: 'restore',
                child: Row(
                  children: [
                    Icon(Icons.restore),
                    SizedBox(width: 8),
                    Text('Restore'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus', style: TextStyle(color: Colors.red)),
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
