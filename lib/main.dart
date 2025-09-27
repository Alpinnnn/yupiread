import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'services/theme_service.dart' as theme_service;
import 'services/data_service.dart';
import 'services/shared_file_handler.dart';
import 'services/language_service.dart';
import 'services/update_service.dart';
import 'services/backup_service.dart';
import 'l10n/app_localizations.dart';
import 'screens/dashboard_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/ebook_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/tools_screen.dart';
import 'services/image_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if running on Android
  if (!Platform.isAndroid) {
    runApp(const NonAndroidApp());
    return;
  }

  // Initialize services for Android
  final dataService = DataService();
  await dataService.initializeData();
  
  final themeService = theme_service.ThemeService.instance;
  await themeService.initialize();
  
  final languageService = LanguageService.instance;
  await languageService.initialize();
  
  final imageCacheService = ImageCacheService.instance;
  await imageCacheService.initialize();

  // Initialize backup service for OAuth session persistence
  final backupService = BackupService.instance;
  await backupService.initialize();

  // Initialize shared file handler
  SharedFileHandler.initialize();

  runApp(YupiwatchApp(themeService: themeService, languageService: languageService));
}

class YupiwatchApp extends StatefulWidget {
  final theme_service.ThemeService themeService;
  final LanguageService languageService;
  
  const YupiwatchApp({super.key, required this.themeService, required this.languageService});

  @override
  State<YupiwatchApp> createState() => _YupiwatchAppState();
}

class _YupiwatchAppState extends State<YupiwatchApp> {
  @override
  void initState() {
    super.initState();
    widget.themeService.addListener(_onThemeChanged);
    widget.languageService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    widget.themeService.removeListener(_onThemeChanged);
    widget.languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  ThemeMode _getFlutterThemeMode(theme_service.ThemeMode customThemeMode) {
    switch (customThemeMode) {
      case theme_service.ThemeMode.light:
        return ThemeMode.light;
      case theme_service.ThemeMode.dark:
        return ThemeMode.dark;
      case theme_service.ThemeMode.system:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yupiread',
      theme: theme_service.ThemeService.lightTheme,
      darkTheme: theme_service.ThemeService.darkTheme,
      themeMode: _getFlutterThemeMode(widget.themeService.themeMode),
      locale: widget.languageService.currentLocale,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

// Non-Android platform app
class NonAndroidApp extends StatelessWidget {
  const NonAndroidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yupiread',
      home: const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Where as reality comes into eternity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final DataService _dataService = DataService.instance;
  
  void _onDataServiceChanged() {
    setState(() {
      final oldScreensLength = _screens.length;
      final isOnProfileScreen = _currentIndex == oldScreensLength - 1;
      
      // Calculate new screens length after the change
      final newScreens = _getScreensList();
      final newScreensLength = newScreens.length;
      
      // If user was on Profile screen, keep them there (Profile is always last)
      if (isOnProfileScreen) {
        _currentIndex = newScreensLength - 1;
      }
      // If current index is out of bounds, reset to last valid position
      else if (_currentIndex >= newScreensLength) {
        _currentIndex = newScreensLength - 1;
      }
      // Otherwise, keep current index as is
    });
  }

  List<Widget> _getScreensList() {
    final screens = [
      const DashboardScreen(),
      const GalleryScreen(),
      const EbookScreen(),
    ];
    
    if (_dataService.showToolsSection) {
      screens.add(const ToolsScreen());
    }
    
    screens.add(const ProfileScreen());
    return screens;
  }

  List<Widget> get _screens => _getScreensList();

  List<BottomNavigationBarItem> _buildBottomNavItems(BuildContext context) {
    final items = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: const Icon(Icons.dashboard_outlined),
        activeIcon: const Icon(Icons.dashboard),
        label: AppLocalizations.of(context).dashboard,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.photo_library_outlined),
        activeIcon: const Icon(Icons.photo_library),
        label: AppLocalizations.of(context).gallery,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.menu_book_outlined),
        activeIcon: const Icon(Icons.menu_book),
        label: AppLocalizations.of(context).ebooks,
      ),
    ];

    // Add Tools tab if enabled
    if (_dataService.showToolsSection) {
      items.add(
        BottomNavigationBarItem(
          icon: const Icon(Icons.build_outlined),
          activeIcon: const Icon(Icons.build),
          label: AppLocalizations.of(context).pdfTools,
        ),
      );
    }

    // Always add Profile at the end
    items.add(
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outlined),
        activeIcon: const Icon(Icons.person),
        label: AppLocalizations.of(context).profile,
      ),
    );

    return items;
  }

  @override
  void initState() {
    super.initState();
    // Add listener for DataService changes
    _dataService.addListener(_onDataServiceChanged);
    // Set context for shared file handler after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('MainScreen: Setting context for SharedFileHandler');
      SharedFileHandler.setContext(context);
      // Check for app updates
      UpdateService.checkForUpdates(context);
    });
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataServiceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          items: _buildBottomNavItems(context),
        ),
      ),
    );
  }
}
