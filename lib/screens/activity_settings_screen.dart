import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/activity_type.dart';

class ActivitySettingsScreen extends StatefulWidget {
  const ActivitySettingsScreen({super.key});

  @override
  State<ActivitySettingsScreen> createState() => _ActivitySettingsScreenState();
}

class _ActivitySettingsScreenState extends State<ActivitySettingsScreen> {
  final DataService _dataService = DataService.instance;
  Map<ActivityType, bool> _activityPreferences = {};

  @override
  void initState() {
    super.initState();
    _loadActivityPreferences();
  }

  void _loadActivityPreferences() {
    setState(() {
      _activityPreferences = _dataService.getActivityPreferences();
    });
  }

  void _updateActivityPreference(ActivityType type, bool enabled) {
    setState(() {
      _activityPreferences[type] = enabled;
    });
    _dataService.setActivityPreference(type, enabled);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled 
            ? '${_getActivityDisplayName(type)} diaktifkan'
            : '${_getActivityDisplayName(type)} dinonaktifkan'
        ),
        backgroundColor: enabled ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _getActivityDisplayName(ActivityType type) {
    switch (type) {
      case ActivityType.photoAdded:
        return 'Foto Ditambahkan';
      case ActivityType.photoDeleted:
        return 'Foto Dihapus';
      case ActivityType.photoEdited:
        return 'Foto Diedit';
      case ActivityType.photoViewed:
        return 'Foto Dilihat';
      case ActivityType.photoPageAdded:
        return 'Halaman Foto Ditambahkan';
      case ActivityType.photoPageDeleted:
        return 'Halaman Foto Dihapus';
      case ActivityType.photoPageEdited:
        return 'Halaman Foto Diedit';
      case ActivityType.ebookRead:
        return 'Ebook Dibaca';
      case ActivityType.ebookCreated:
        return 'Ebook Dibuat';
      case ActivityType.ebookAdded:
        return 'Ebook Ditambahkan';
      case ActivityType.ebookCompleted:
        return 'Ebook Selesai';
      case ActivityType.ebookDeleted:
        return 'Ebook Dihapus';
      case ActivityType.ebookEdited:
        return 'Ebook Diedit';
      case ActivityType.streakStart:
        return 'Streak Dimulai';
      case ActivityType.streakContinue:
        return 'Streak Berlanjut';
      case ActivityType.streakEnd:
        return 'Streak Berakhir';
    }
  }

  String _getActivityDescription(ActivityType type) {
    switch (type) {
      case ActivityType.photoAdded:
        return 'Log ketika foto baru ditambahkan ke galeri';
      case ActivityType.photoDeleted:
        return 'Log ketika foto dihapus dari galeri';
      case ActivityType.photoEdited:
        return 'Log ketika foto diedit atau diubah';
      case ActivityType.photoViewed:
        return 'Log ketika foto dibuka dan dilihat';
      case ActivityType.photoPageAdded:
        return 'Log ketika halaman foto multi-foto dibuat';
      case ActivityType.photoPageDeleted:
        return 'Log ketika halaman foto dihapus';
      case ActivityType.photoPageEdited:
        return 'Log ketika halaman foto diedit';
      case ActivityType.ebookRead:
        return 'Log ketika ebook dibaca atau dibuka';
      case ActivityType.ebookCreated:
        return 'Log ketika ebook baru dibuat';
      case ActivityType.ebookAdded:
        return 'Log ketika ebook diimpor atau ditambahkan';
      case ActivityType.ebookCompleted:
        return 'Log ketika ebook selesai dibaca';
      case ActivityType.ebookDeleted:
        return 'Log ketika ebook dihapus';
      case ActivityType.ebookEdited:
        return 'Log ketika ebook diedit atau diubah';
      case ActivityType.streakStart:
        return 'Log ketika streak membaca baru dimulai';
      case ActivityType.streakContinue:
        return 'Log ketika streak membaca berlanjut';
      case ActivityType.streakEnd:
        return 'Log ketika streak membaca diakhiri';
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.photoAdded:
        return Icons.add_photo_alternate;
      case ActivityType.photoDeleted:
        return Icons.delete_outline;
      case ActivityType.photoEdited:
        return Icons.edit_outlined;
      case ActivityType.photoViewed:
        return Icons.visibility_outlined;
      case ActivityType.photoPageAdded:
        return Icons.collections;
      case ActivityType.photoPageDeleted:
        return Icons.delete_sweep;
      case ActivityType.photoPageEdited:
        return Icons.edit_note;
      case ActivityType.ebookRead:
        return Icons.menu_book_outlined;
      case ActivityType.ebookCreated:
        return Icons.create_new_folder;
      case ActivityType.ebookAdded:
        return Icons.library_add;
      case ActivityType.ebookCompleted:
        return Icons.task_alt;
      case ActivityType.ebookDeleted:
        return Icons.auto_delete;
      case ActivityType.ebookEdited:
        return Icons.edit_document;
      case ActivityType.streakStart:
        return Icons.local_fire_department;
      case ActivityType.streakContinue:
        return Icons.trending_up;
      case ActivityType.streakEnd:
        return Icons.stop_circle;
    }
  }

  Color _getActivityColor(ActivityType type) {
    if (type.toString().contains('photo')) {
      return const Color(0xFF3B82F6); // Blue for photos
    } else if (type.toString().contains('ebook')) {
      return const Color(0xFF10B981); // Green for ebooks
    } else if (type.toString().contains('streak')) {
      switch (type) {
        case ActivityType.streakStart:
          return const Color(0xFF10B981); // Green for starting streak
        case ActivityType.streakContinue:
          return const Color(0xFF2563EB); // Blue for continuing streak
        case ActivityType.streakEnd:
          return const Color(0xFFEF4444); // Red for ending streak
        default:
          return const Color(0xFF8B5CF6); // Purple default
      }
    }
    return const Color(0xFF8B5CF6); // Purple default
  }

  Widget _buildActivityToggle(ActivityType type) {
    final isEnabled = _activityPreferences[type] ?? true;
    final color = _getActivityColor(type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).cardTheme.shadowColor ??
                Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getActivityIcon(type),
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          _getActivityDisplayName(type),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        subtitle: Text(
          _getActivityDescription(type),
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        trailing: Switch(
          value: isEnabled,
          onChanged: (value) => _updateActivityPreference(type, value),
          activeColor: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Activity Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF3B82F6),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kontrol Activity Log',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pilih aktivitas mana yang ingin dicatat dalam log aktivitas dashboard.',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Photo Activities Section
            Text(
              'Aktivitas Foto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.headlineSmall?.color,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityToggle(ActivityType.photoAdded),
            _buildActivityToggle(ActivityType.photoDeleted),
            _buildActivityToggle(ActivityType.photoEdited),
            _buildActivityToggle(ActivityType.photoViewed),
            _buildActivityToggle(ActivityType.photoPageAdded),
            _buildActivityToggle(ActivityType.photoPageDeleted),
            _buildActivityToggle(ActivityType.photoPageEdited),
            
            const SizedBox(height: 32),
            
            // Ebook Activities Section
            Text(
              'Aktivitas Ebook',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.headlineSmall?.color,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityToggle(ActivityType.ebookRead),
            _buildActivityToggle(ActivityType.ebookCreated),
            _buildActivityToggle(ActivityType.ebookAdded),
            _buildActivityToggle(ActivityType.ebookCompleted),
            _buildActivityToggle(ActivityType.ebookDeleted),
            _buildActivityToggle(ActivityType.ebookEdited),
            
            const SizedBox(height: 32),
            
            // Reset Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reset ke Default'),
                      content: const Text(
                        'Apakah Anda yakin ingin mengatur ulang semua pengaturan aktivitas ke default (semua diaktifkan)?'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _dataService.resetActivityPreferences();
                            _loadActivityPreferences();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pengaturan aktivitas direset ke default'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset ke Default'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: const Color(0xFFF59E0B)),
                  foregroundColor: const Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
