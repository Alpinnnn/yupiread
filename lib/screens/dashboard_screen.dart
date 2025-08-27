import 'package:flutter/material.dart';
import '../models/photo_model.dart';
import '../services/data_service.dart';
import '../models/activity_type.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DataService _dataService = DataService.instance;

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Ringkasan aktivitas Anda',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              // Statistics Cards with responsive layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final cardWidth =
                      (screenWidth - 16) / 2; // 2 columns with spacing

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildStatCard(
                          context,
                          icon: Icons.photo_library,
                          title: 'Total Foto',
                          value: '${_dataService.totalPhotos}',
                          subtitle: 'Catatan tersimpan',
                          color: const Color(0xFF3B82F6),
                          backgroundColor: const Color(
                            0xFF3B82F6,
                          ).withOpacity(0.1),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildStatCard(
                          context,
                          icon: Icons.menu_book,
                          title: 'Total Ebook',
                          value: '${_dataService.totalEbooks}',
                          subtitle: 'Ebook dibuat',
                          color: const Color(0xFF10B981),
                          backgroundColor: const Color(
                            0xFF10B981,
                          ).withOpacity(0.1),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildStatCard(
                          context,
                          icon: Icons.schedule,
                          title: 'Waktu Baca',
                          value: _dataService.formattedReadingTime,
                          subtitle: 'Total membaca',
                          color: const Color(0xFF8B5CF6),
                          backgroundColor: const Color(
                            0xFF8B5CF6,
                          ).withOpacity(0.1),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildStatCard(
                          context,
                          icon: Icons.local_fire_department,
                          title: 'Reading Streak',
                          value: '${_dataService.readingStreak} hari',
                          subtitle: 'Berturut-turut',
                          color: const Color(0xFFF59E0B),
                          backgroundColor: const Color(
                            0xFFF59E0B,
                          ).withOpacity(0.1),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildRecentActivity(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineMedium?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final activities = _dataService.activities.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aktivitas Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                ),
              ),
              TextButton(
                onPressed: () {
                  _showAllActivities(context);
                },
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Belum ada aktivitas',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...activities.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value;
              return Column(
                children: [
                  if (index > 0) const SizedBox(height: 12),
                  _buildActivityItem(
                    icon: _getActivityIcon(activity.type),
                    title: activity.title,
                    time: activity.timeAgo,
                    color: Color(activity.type.colorValue),
                  ),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.photoAdded:
        return Icons.photo_camera;
      case ActivityType.photoViewed:
        return Icons.visibility;
      case ActivityType.photoDeleted:
        return Icons.delete;
      case ActivityType.photoEdited:
        return Icons.edit;
      case ActivityType.photoPageAdded:
        return Icons.collections;
      case ActivityType.photoPageDeleted:
        return Icons.delete_sweep;
      case ActivityType.photoPageEdited:
        return Icons.edit_note;
      case ActivityType.ebookAdded:
        return Icons.add_circle;
      case ActivityType.ebookRead:
        return Icons.menu_book;
      case ActivityType.ebookCompleted:
        return Icons.check_circle;
      case ActivityType.ebookDeleted:
        return Icons.delete;
      case ActivityType.ebookEdited:
        return Icons.edit;
      case ActivityType.ebookCreated:
        return Icons.add_circle;
    }
  }

  void _showAllActivities(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Semua Aktivitas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _dataService.activities.length,
                    itemBuilder: (context, index) {
                      final activity = _dataService.activities[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: _buildActivityItem(
                          icon: _getActivityIcon(activity.type),
                          title: activity.title,
                          time: activity.timeAgo,
                          color: Color(activity.type.colorValue),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
