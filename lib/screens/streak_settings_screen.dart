import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../l10n/app_localizations.dart';

class StreakSettingsScreen extends StatefulWidget {
  const StreakSettingsScreen({super.key});

  @override
  State<StreakSettingsScreen> createState() => _StreakSettingsScreenState();
}

class _StreakSettingsScreenState extends State<StreakSettingsScreen> {
  final DataService _dataService = DataService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.streakTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.appBarTheme.foregroundColor,
            fontSize: 18,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Streak Statistics Card
              _buildStreakStatsCard(localizations, theme),
              
              const SizedBox(height: 24),
              
              // Streak Actions
              _buildStreakActionsCard(localizations, theme),
              
              const SizedBox(height: 24),
              
              // Reminder Settings
              _buildReminderSettingsCard(localizations, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakStatsCard(AppLocalizations localizations, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.cardTheme.shadowColor ?? Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.streakTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.headlineMedium?.color,
            ),
          ),
          const SizedBox(height: 16),
          
          // Current and Longest Streak
          Row(
            children: [
              Expanded(
                child: _buildStreakStat(
                  localizations.currentStreak,
                  '${_dataService.readingStreak}',
                  localizations.streakDays,
                  const Color(0xFF2563EB),
                  theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStreakStat(
                  localizations.longestStreak,
                  '${_dataService.longestStreak}',
                  localizations.streakDays,
                  const Color(0xFF10B981),
                  theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStat(String title, String value, String unit, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakActionsCard(AppLocalizations localizations, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.cardTheme.shadowColor ?? Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.headlineMedium?.color,
            ),
          ),
          const SizedBox(height: 16),
          
          // End Streak Button
          if (_dataService.readingStreak > 0)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _showEndStreakDialog,
                icon: const Icon(Icons.stop_circle, size: 20),
                label: Text(localizations.endStreak),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.keepStreakAlive,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start reading to begin your streak!',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReminderSettingsCard(AppLocalizations localizations, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.cardTheme.shadowColor ?? Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.streakReminder,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.headlineMedium?.color,
            ),
          ),
          const SizedBox(height: 16),
          
          // Enable Reminder Switch
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.enableStreakReminder,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.streakReminderMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _dataService.streakReminderEnabled,
                onChanged: _toggleStreakReminder,
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
          
          if (_dataService.streakReminderEnabled) ...[
            const SizedBox(height: 16),
            
            // Reminder Time Setting
            Row(
              children: [
                Expanded(
                  child: Text(
                    localizations.streakReminderTime,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _selectReminderTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _dataService.streakReminderTime,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showEndStreakDialog() {
    final localizations = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.endStreakConfirmTitle),
        content: Text(localizations.endStreakConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endStreak();
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: Text(localizations.endStreak),
          ),
        ],
      ),
    );
  }

  Future<void> _endStreak() async {
    final localizations = AppLocalizations.of(context);
    
    setState(() {
      _isLoading = true;
    });

    try {
      await _dataService.endStreak();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.streakEndedSuccessfully),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end streak: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleStreakReminder(bool enabled) async {
    final localizations = AppLocalizations.of(context);
    
    if (enabled) {
      // Request notification permission
      final hasPermission = await _notificationService.requestPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission is required for reminders'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
        return;
      }
    }

    await _dataService.setStreakReminderEnabled(enabled);
    await _notificationService.updateStreakReminder();
    
    if (mounted) {
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled 
            ? localizations.streakReminderEnabled 
            : localizations.streakReminderDisabled),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _selectReminderTime() async {
    final currentTime = _dataService.streakReminderTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(currentTime[0]),
      minute: int.parse(currentTime[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      final timeString = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      await _dataService.setStreakReminderTime(timeString);
      await _notificationService.updateStreakReminder();
      
      if (mounted) {
        setState(() {});
      }
    }
  }
}
