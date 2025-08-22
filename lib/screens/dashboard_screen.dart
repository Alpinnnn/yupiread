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
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _dataService.initializeSampleData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
                          backgroundColor: const Color(0xFFEFF6FF),
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
                          backgroundColor: const Color(0xFFECFDF5),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildStatCard(
                          context,
                          icon: Icons.schedule,
                          title: 'Waktu Baca',
                          value: _dataService.totalReadingTime,
                          subtitle: 'Total membaca',
                          color: const Color(0xFF8B5CF6),
                          backgroundColor: const Color(0xFFF3E8FF),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildStatCard(
                          context,
                          icon: Icons.trending_up,
                          title: 'Aktivitas',
                          value: '${_dataService.activityStreak} hari',
                          subtitle: 'Streak harian',
                          color: const Color(0xFFF59E0B),
                          backgroundColor: const Color(0xFFFEF3C7),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A4A4A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              const Text(
                'Aktivitas Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              TextButton(
                onPressed: () {
                  _showAllActivities(context);
                },
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(fontSize: 14, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Belum ada aktivitas',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
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
                const Text(
                  'Semua Aktivitas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
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
