import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get dashboard => 'Dashboard';

  @override
  String get gallery => 'Gallery';

  @override
  String get ebooks => 'Ebooks';

  @override
  String get profile => 'Profile';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get share => 'Share';

  @override
  String get add => 'Add';

  @override
  String get search => 'Search';

  @override
  String get settings => 'Settings';

  @override
  String get appSettings => 'App Settings';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get themeSettings => 'Theme Settings';

  @override
  String get activitySettings => 'Activity Settings';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get currentLanguage => 'Current Language';

  @override
  String get sharedImage => 'Shared Image';

  @override
  String get whatToDoWithImage => 'What would you like to do with this image?';

  @override
  String get addToGallery => 'Add to Gallery';

  @override
  String get scanText => 'Scan Text';

  @override
  String get imageAddedToGallery => 'Image successfully added to gallery';

  @override
  String get documentAddedAndOpened => 'Document successfully added and opened';

  @override
  String get documentOpenedWith => 'Document successfully opened with Yupiread';

  @override
  String get failedToAddDocument => 'Failed to add document';

  @override
  String get textScanner => 'Text Scanner';

  @override
  String get scanResults => 'Scan Results';

  @override
  String get textRecognitionFailed => 'Text recognition failed';

  @override
  String get noTextDetected => 'No text detected';

  @override
  String get textExtractionFailed => 'Failed to extract text: ';

  @override
  String get enterEditTextHere => 'Enter or edit ebook text here...';

  @override
  String get saving => 'Saving...';

  @override
  String get extractingText => 'Extracting text...';

  @override
  String get scanningText => 'Scanning text...';

  @override
  String get textRecognitionTitle => 'Text Recognition';

  @override
  String get scannedImage => 'Scanned Image';

  @override
  String get saveToGallery => 'Save to Gallery';

  @override
  String get noInternetConnection => 'Cannot connect to internet';

  @override
  String errorOccurredWith(String error) => 'An error occurred: $error';

  @override
  String get editScannedText => 'Edit scanned text...';

  String get imageAndTextSaved =>
      'Image and text successfully saved to gallery';

  String get failedToSaveToGallery => 'Failed to save to gallery';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No data available';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get scanDocument => 'Scan Document';

  @override
  String get addEbook => 'Add Ebook';

  @override
  String get viewGallery => 'View Gallery';

  @override
  String get statistics => 'Statistics';

  @override
  String get totalPhotos => 'Total Photos';

  @override
  String get totalEbooks => 'Total Ebooks';

  @override
  String get totalActivities => 'Total Activities';

  @override
  String get days => 'days';

  @override
  String get consecutive => 'consecutive';

  // Galleryride
  String get myGallery => 'My Gallery';

  @override
  String get photos => 'Photos';

  @override
  String get photoPages => 'Photo Pages';

  @override
  String get createPhotoPage => 'Create Photo Page';

  @override
  String get noPhotosYet => 'No photos yet';

  @override
  String get addFirstPhoto => 'Add your first photo';

  @override
  String get sortBy => 'Sort by';

  @override
  String get filterByTag => 'Filter by tag';

  @override
  String get allTags => 'All Tags';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get newNote => 'New Note';

  @override
  String get failedToLoad => 'Failed to load';

  @override
  String get addPhotoNote => 'Add Photo Note';

  // Gallery Screen Specific
  @override
  String get photoTitle => 'Photo Title';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get selectTagsOptional => 'Select Tags (Optional):';

  @override
  String get failedToSavePhoto => 'Failed to save photo';

  @override
  String photoAddedSuccessfully(String title) =>
      'Photo "$title" successfully added';

  @override
  String get selectSaveMethod => 'Select Save Method';

  @override
  String documentsScannedCount(int count) =>
      '$count documents successfully scanned.';

  @override
  String get multiDocumentPage => 'Multi-Document Page';

  @override
  String get multiDocumentPageDesc => 'All documents in one swipeable page';

  @override
  String get separateDocuments => 'Separate Documents';

  @override
  String get separateDocumentsDesc =>
      'Each document as separate item in gallery';

  @override
  String get noTagsAvailableForFilter => 'No tags available for filter yet';

  @override
  String get filterByTags => 'Filter by Tags';

  @override
  String get reset => 'Reset';

  @override
  String get deletePhotoTitle => 'Delete Photo';

  @override
  String deletePhotoMessage(String title) =>
      'Are you sure you want to delete "$title"?';

  // Ebooksverride
  String get myEbooks => 'My Ebooks';

  @override
  String get addNewEbook => 'Add New Ebook';

  @override
  String get noEbooksYet => 'No ebooks yet';

  @override
  String get addFirstEbook => 'Add your first ebook';

  @override
  String get recentlyRead => 'Recently Read';

  @override
  String get favorites => 'Favorites';

  @override
  String get importEbook => 'Import Ebook';

  @override
  String get readAction => 'Read';

  @override
  String get editAction => 'Edit';

  @override
  String get deleteAction => 'Delete';

  @override
  String get myActivity => 'My Activity';

  @override
  String get streakLabel => 'Streak';

  @override
  String get readingTimeLabel => 'Reading Time';

  @override
  String get totalReading => 'Total reading';

  @override
  String get readingStreakLabel => 'Reading Streak';

  @override
  String get viewAll => 'View All';

  @override
  String get noActivityYet => 'No activity yet';

  @override
  String get allActivities => 'All Activities';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get changeProfilePhoto => 'Change Profile Photo';

  @override
  String get enterUsername => 'Enter username';

  @override
  String get username => 'Username';

  @override
  String get languageChanged => 'Language Changed';

  @override
  String get restartAppMessage =>
      'Please restart the app to apply the new language setting';

  @override
  String get ok => 'OK';

  @override
  String get maxCharacters => 'Maximum 10 characters';

  @override
  String get usernameMaxError => 'Username cannot be more than 10 characters';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get importPdfOrWord => 'Import PDF or Word files to start reading';

  @override
  String get cameraOption => 'Camera';

  @override
  String get galleryOption => 'Gallery';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get profilePhotoUpdated => 'Profile photo updated successfully';

  @override
  String get failedToUpdatePhoto => 'Failed to update profile photo';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get deletingData => 'Deleting data...';

  @override
  String get allDataDeleted => 'All data deleted successfully';

  @override
  String get failedToDeleteData => 'Failed to delete data';

  @override
  String get pdfFile => 'PDF File';

  @override
  String get importPdfDocument => 'Import PDF document';

  @override
  String get wordFile => 'Word File';

  @override
  String get importWordDocument => 'Import Word document';

  @override
  String get textEbook => 'Text Ebook';

  @override
  String get createNewTextEbook => 'Create new text ebook';

  @override
  String get failedToImportPdf => 'Failed to import PDF file';

  @override
  String get convertingWordToPdf => 'Converting Word to PDF...';

  @override
  String get failedToConvertWord => 'Failed to convert Word to PDF';

  @override
  String get failedToImportWord => 'Failed to import Word file';

  // Activity Log Messages
  @override
  String photoAdded(String title) => 'Photo "$title" added';

  @override
  String get photoAddedDesc => 'New photo note successfully saved';

  @override
  String photoDeleted(String title) => 'Photo "$title" deleted';

  @override
  String get photoDeletedDesc => 'Photo note has been deleted from gallery';

  @override
  String photoRenamed(String oldTitle, String newTitle) =>
      'Photo "$oldTitle" renamed to "$newTitle"';

  @override
  String get photoRenamedDesc => 'Photo name successfully updated';

  @override
  String photoEdited(String title) => 'Photo "$title" edited';

  @override
  String get photoEditedDesc => 'Photo details successfully updated';

  @override
  String ebookAdded(String title) => 'Ebook "$title" added';

  @override
  String get ebookAddedDesc => 'New ebook note successfully saved';

  @override
  String ebookDeleted(String title) => 'Ebook "$title" deleted';

  @override
  String get ebookDeletedDesc => 'Ebook note has been deleted from gallery';

  @override
  String ebookRenamed(String oldTitle, String newTitle) =>
      'Ebook "$oldTitle" renamed to "$newTitle"';

  @override
  String get ebookRenamedDesc => 'Ebook name successfully updated';

  @override
  String ebookEdited(String title) => 'Ebook "$title" edited';

  @override
  String get ebookEditedDesc => 'Ebook details successfully updated';

  @override
  String photoPageAdded(String title) => 'Photo page "$title" added';

  @override
  String photoPageAddedDesc(int count) =>
      'Photo page with $count photos successfully saved';

  @override
  String photoPageDeleted(String title) => 'Photo page "$title" deleted';

  @override
  String get photoPageDeletedDesc =>
      'Photo page note has been deleted from gallery';

  @override
  String photoPageRenamed(String oldTitle, String newTitle) =>
      'Photo page "$oldTitle" renamed to "$newTitle"';

  @override
  String get photoPageRenamedDesc => 'Photo page name successfully updated';

  @override
  String photoPageEdited(String title) => 'Photo page "$title" edited';

  @override
  String get photoPageEditedDesc => 'Photo page details successfully updated';

  // Profile
  String get myProfile => 'My Profile';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get aboutApp => 'About App';

  @override
  String get version => 'Version';

  @override
  String get developer => 'Developer';

  // Document Scanner
  @override
  String get scanFromCamera => 'Scan from Camera';

  @override
  String get scanFromGallery => 'Scan from Gallery';

  @override
  String get scanWithCamera => 'Scan with Camera';

  @override
  String get selectFromGallery => 'Select from Gallery';

  @override
  String get autoDetectEdges => 'Auto detect document edges in real-time';

  @override
  String get cropFromExisting => 'Crop document from existing photos';

  @override
  String get scannedFromCamera => 'Document Scanned from Camera';

  @override
  String get scannedFromGallery => 'Document Scanned from Gallery';

  @override
  String get photoFromGallery => 'Photo from Gallery';

  // Bottom Menu Actions
  @override
  String get editPhoto => 'Edit Photo';

  @override
  String get editPhotoPage => 'Edit Photo Page';

  @override
  String get deletePhoto => 'Delete Photo';

  @override
  String get deletePhotoPage => 'Delete Photo Page';

  @override
  String get deleteConfirmation => 'Are you sure you want to delete';

  @override
  String get deletePhotoConfirmation =>
      'Are you sure you want to delete this photo?';

  @override
  String get deletePhotoPageConfirmation =>
      'Are you sure you want to delete this photo page?';

  // Theme Settings
  @override
  String get selectTheme => 'Select Theme';

  @override
  String get followSystem => 'Follow System';

  @override
  String get followSystemDesc => 'Theme will follow device system settings';

  @override
  String get lightTheme => 'Light Theme';

  @override
  String get lightThemeDesc => 'Display with light background';

  @override
  String get darkTheme => 'Dark Theme';

  @override
  String get darkThemeDesc => 'Display with dark background';

  @override
  String get apply => 'Apply';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'Follow System';

  // Common Error Messages
  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get fileNotFound => 'File not found';

  @override
  String get accessDenied => 'Access denied';

  @override
  String get fileInUse => 'File is in use';

  @override
  String get fileSystemError => 'File system error';

  @override
  String get invalidDataFormat => 'Invalid data format';

  @override
  String get connectionError => 'Cannot connect to internet';

  @override
  String errorMessage(String error) => 'An error occurred: $error';

  // Default Tags
  @override
  String get tagNotes => 'Notes';

  @override
  String get tagImportant => 'Important';

  @override
  String get tagTasks => 'Tasks';

  @override
  String get tagIdeas => 'Ideas';

  @override
  String get tagReference => 'Reference';

  @override
  String get defaultUser => 'User';

  // Shared Files
  @override
  String get sharedImageDesc => 'Image shared from external app';

  @override
  String get sharedDocumentDesc => 'Document shared from external app';

  // Text Reader
  @override
  String get readerSettings => 'Reader Settings';

  @override
  String get fontSize => 'Font Size: ';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get close => 'Close';

  @override
  String get textCopiedToClipboard => 'Text successfully copied to clipboard';

  @override
  String get textReader => 'Text Reader';

  @override
  String get copyText => 'Copy Text';

  @override
  String get back => 'Back';

  @override
  String get readingFailed => 'Failed to read file: ';

  // Text to Ebook Editor
  @override
  String get ebookFromText => 'Ebook from Text';

  @override
  String extractingTextFromImages(int count) =>
      'Extracting text from $count images...';

  @override
  String get noTextExtracted =>
      'No text was successfully extracted from images';

  @override
  String get textExtractedSuccess =>
      'Text successfully extracted! You can edit it before saving.';

  @override
  String extractionFailed(String error) => 'Failed to extract text: $error';

  @override
  String get selectTags => 'Select Tags';

  @override
  String get done => 'Done';

  @override
  String get ebookTitleRequired => 'Ebook title cannot be empty';

  @override
  String get textContentRequired => 'Text content cannot be empty';

  @override
  String get ebookSavedSuccess => 'Ebook successfully saved!';

  @override
  String ebookSaveFailed(String error) => 'Failed to save ebook: $error';

  @override
  String get editEbook => 'Edit Ebook';

  @override
  String get createEbookFromText => 'Create Ebook from Text';

  @override
  String get saveEbook => 'Save Ebook';

  @override
  String get ebookTitle => 'Ebook Title';

  @override
  String tagsCount(int count) => 'Tags ($count)';

  @override
  String get textContent => 'Text Content';

  // Text Recognition
  @override
  String pageNumber(int page) => '--- Page $page ---';

  // Tools Settings
  @override
  String get toolsSettings => 'Tools Settings';

  @override
  String get alwaysShowToolSection => 'Always Show Tool Section';

  @override
  String get toolsSectionDesc => 'Show Tools tab in bottom navigation';

  @override
  String get tools => 'Tools';

  @override
  String get compressPdf => 'Compress PDF';

  @override
  String get mergePdf => 'Merge PDF';

  @override
  String get compressPdfDesc => 'Compress PDF files to reduce size';

  @override
  String get mergePdfDesc => 'Merge multiple PDF files into one';

  @override
  String get selectPdfsToCompress => 'Select PDFs to Compress';

  @override
  String get selectPdfsToMerge => 'Select PDFs to Merge';

  @override
  String get addFromFileManager => 'Add from File Manager';

  @override
  String get compressing => 'Compressing...';

  @override
  String get merging => 'Merging...';

  @override
  String get compressionComplete => 'Compression completed successfully';

  @override
  String get mergeComplete => 'Merge completed successfully';

  @override
  String get compressionFailed => 'Compression failed';

  @override
  String get mergeFailed => 'Merge failed';

  @override
  String get selectAtLeastOnePdf => 'Please select at least one PDF';

  @override
  String get selectAtLeastTwoPdfs => 'Please select at least two PDFs to merge';

  @override
  String get noPdfsAvailable => 'No PDF files available';

  @override
  String get addPdfsFirst => 'Add some PDF files first';

  @override
  String get compress => 'Compress';

  @override
  String get merge => 'Merge';

  @override
  String get pdfTools => 'Tools';

  @override
  String pdfsSelected(int count) => '$count PDFs selected';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  // Language Selection Dialog
  @override
  String get selectLanguageTitle => 'Select Language';

  @override
  String get indonesianLanguage => 'Bahasa Indonesia';

  @override
  String get englishLanguage => 'English';

  @override
  String get indonesianLanguageDesc => 'Use Indonesian language for the app';

  @override
  String get englishLanguageDesc => 'Use English language for the app';

  @override
  String get languageChangedSuccess => 'Language changed successfully';

  // Streak Features
  @override
  String get streakTitle => 'Reading Streak';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get longestStreak => 'Longest Streak';

  @override
  String get streakDays => 'days';

  @override
  String get endStreak => 'End Streak';

  @override
  String get endStreakConfirmTitle => 'End Reading Streak?';

  @override
  String get endStreakConfirmMessage => 'Are you sure you want to end your current reading streak? This action cannot be undone.';

  @override
  String get streakEnded => 'Reading streak ended';

  @override
  String get streakEndedSuccessfully => 'Your reading streak has been ended successfully';

  @override
  String get streakReminder => 'Reading Streak Reminder';

  @override
  String get streakReminderMessage => 'Don\'t forget to read today to maintain your streak!';

  @override
  String get streakReminderTime => 'Reminder Time';

  @override
  String get enableStreakReminder => 'Enable Daily Reminder';

  @override
  String get streakReminderEnabled => 'Streak reminder enabled';

  @override
  String get streakReminderDisabled => 'Streak reminder disabled';

  @override
  String get keepStreakAlive => 'Keep your streak alive!';

  @override
  String get readingStreakBroken => 'Reading streak broken';

  @override
  String get streakWillResetTomorrow => 'Your streak will reset tomorrow if you don\'t read today';

  @override
  String streakActivityEndStreak(int days) => 'Ended reading streak of $days days';

  @override
  String streakActivityStartStreak() => 'Started a new reading streak';

  @override
  String streakActivityContinueStreak(int days) => 'Continued reading streak - Day $days';

  @override
  String get languageChangedTitle => 'Language Changed Successfully';

  @override
  String get restartAppRequired =>
      'The app needs to be restarted to apply the language changes.';

  // Profile Screen
  @override
  String get managementSetting => 'Management Setting';

  @override
  String get appSetting => 'App Setting';

  @override
  String get tagSetting => 'Tag Setting';

  @override
  String get gallerySetting => 'Gallery Setting';

  @override
  String get ebookSetting => 'Ebook Setting';

  @override
  String get languageSettingsProfile => 'Language Settings';

  @override
  String get themeSetting => 'Theme Setting';

  @override
  String get activitySettingsProfile => 'Activity Settings';

  @override
  String get removeData => 'Remove Data';

  @override
  String get cropProfilePhoto => 'Crop Profile Photo';

  @override
  String get profilePhotoUpdatedSuccess => 'Profile photo updated successfully';

  @override
  String get failedToUpdateProfilePhoto => 'Failed to update profile photo';

  @override
  String get themeChangedTo => 'Theme changed to';

  @override
  String get toolsSectionEnabled => 'Tools section enabled';

  @override
  String get toolsSectionDisabled => 'Tools section disabled';

  @override
  String get removeAllData => 'Remove All Data';

  @override
  String get removeDataConfirmation =>
      'Are you sure you want to remove all app data? This action cannot be undone and will delete:\n\n• All photos and notes\n• All ebooks and reading progress\n• Activity history\n• Profile settings\n• Custom tags\n\nThe app will start fresh.';

  @override
  String get removeAll => 'Remove All';

  @override
  String get removingData => 'Removing data...';

  @override
  String get allDataRemoved => 'All data successfully removed';

  @override
  String get failedToRemoveData => 'Failed to remove data';

  // Gallery Screen Additional Localization
  @override
  String get failedToSelectPhoto => 'Failed to select photo';

  @override
  String get selectAddMethod => 'Select Add Method';

  @override
  String youSelected(int count) =>
      'You selected $count photos. How would you like to add them?';

  @override
  String get separatePhotos => 'Separate Photos';

  @override
  String get separatePhotosDesc => 'Each photo as separate item in gallery';

  @override
  String get multiPhoto => 'Multi-Photo';

  @override
  String addPhotosCount(int count) => 'Add $count Photos';

  @override
  String get titlePrefix => 'Title Prefix (will add number)';

  @override
  String get descriptionOptionalShort => 'Description (optional)';

  @override
  String get tagsOptional => 'Tags (optional):';

  @override
  String get newTagsComma => 'New tags (separate with comma)';

  @override
  String get saveAll => 'Save All';

  @override
  String get createPhotoPageTitle => 'Create Photo Page';

  @override
  String photosSelected(int count) => '$count photos selected';

  @override
  String get pageTitle => 'Page Title';

  @override
  String get createPage => 'Create Page';

  @override
  String photosAddedSuccessfully(int count) =>
      '$count photos successfully added';

  @override
  String photoPageCreatedSuccess(String title, int count) =>
      'Photo page "$title" successfully created with $count photos';

  @override
  String photoDeletedSuccess(String title) =>
      'Photo "$title" successfully deleted';

  @override
  String failedToSavePhotoError(String error) => 'Failed to save photo: $error';

  @override
  String failedToSelectPhotoError(String error) =>
      'Failed to select photo: $error';

  @override
  String failedToAddPhotosError(String error) => 'Failed to add photos: $error';

  @override
  String get multiPhotoPageTitle => 'Multi-Photo Page';

  @override
  String get multiPhotoPageDesc => 'All photos in one page that can be swiped';

  @override
  String get photoPage => 'Photo Page';

  // Backup & Restore
  @override
  String get backupRestore => 'Backup & Restore';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get signInToGoogleDrive => 'Sign In to Google Drive';

  @override
  String get signOutFromGoogleDrive => 'Sign Out from Google Drive';

  @override
  String get connectedAs => 'Connected as';

  @override
  String get notConnectedToGoogleDrive => 'Not connected to Google Drive';

  @override
  String get createBackup => 'Create Backup';

  @override
  String get backupList => 'Backup List';

  @override
  String get noBackupsYet => 'No backups yet';

  @override
  String get createFirstBackup => 'Create your first backup';

  @override
  String get backupSuccessful => 'Backup successful';

  @override
  String get backupFailed => 'Backup failed';

  @override
  String get restoreSuccessful => 'Restore successful';

  @override
  String get restoreFailed => 'Restore failed';

  @override
  String get deleteBackup => 'Delete Backup';

  @override
  String get confirmRestore => 'Confirm Restore';

  @override
  String get confirmRestoreMessage =>
      'Are you sure you want to restore data from this backup?\n\nAll current data will be replaced with backup data.';

  @override
  String get confirmDeleteBackup =>
      'Are you sure you want to delete this backup?';

  @override
  String get backupDeleted => 'Backup successfully deleted';

  @override
  String get failedToDeleteBackup => 'Failed to delete backup';

  @override
  String get failedToLoadBackups => 'Failed to load backup list';

  @override
  String get signInSuccessful => 'Successfully signed in to Google Drive';

  @override
  String get signInFailed => 'Failed to sign in to Google Drive';

  @override
  String get signOutSuccessful => 'Successfully signed out from Google Drive';

  @override
  String get pleaseSignInFirst => 'Please sign in to Google Drive first';

  @override
  String get refreshing => 'Refreshing...';

  @override
  String get autoBackup => 'Auto Backup';

  @override
  String get autoBackupInterval => 'Auto Backup Interval';

  @override
  String get enableAutoBackup => 'Enable Auto Backup';

  @override
  String get selectInterval => 'Select Interval';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get autoBackupEnabled => 'Auto backup enabled';

  @override
  String get autoBackupDisabled => 'Auto backup disabled';

  @override
  String get daysAgo => 'days ago';

  @override
  String get hoursAgo => 'hours ago';

  @override
  String get minutesAgo => 'minutes ago';

  @override
  String get justNow => 'Just now';

  @override
  String get signInToViewBackups => 'Sign in to Google Drive to view backups';

  @override
  String get backingUp => 'Backing up...';

  @override
  String get signOut => 'Sign Out';

  // Development Section
  @override
  String get development => 'Development';

  @override
  String get supportDevelopment => 'Support Development';

  @override
  String get githubRepository => 'GitHub Repository';

  // Update Dialog
  @override
  String get updateAvailable => 'Update Available';

  @override
  String get updateLater => 'Later';

  @override
  String get updateNow => 'Update';

  // Common Actions and Messages (New)
  @override
  String get finished => 'Finished';

  @override
  String get goBack => 'Go Back';

  @override
  String get saveDocument => 'Save Document';

  @override
  String get updateDocument => 'Update Document';

  @override
  String get createNewEbook => 'Create New Ebook';

  @override
  String get newEbook => 'New Ebook';

  @override
  String get documentSavedSuccessfully => 'Document saved successfully';

  @override
  String get documentUpdatedSuccessfully => 'Document updated successfully';

  @override
  String get ebookNotFound => 'Ebook not found';

  @override
  String get editTags => 'Edit Tags';

  // Tag Management (New)
  @override
  String get tagSettings => 'Tag Settings';

  @override
  String get addNewTag => 'Add New Tag';

  @override
  String get tagList => 'Tag List';

  @override
  String get availableTags => 'Available Tags';

  @override
  String get noTagsAvailable => 'No tags available';

  @override
  String get addTagsToOrganize => 'Add tags to organize your photos and ebooks';

  @override
  String get tagNameEmpty => 'Tag name cannot be empty';

  @override
  String tagAddedSuccessfully(String tagName) =>
      'Tag "$tagName" added successfully';

  @override
  String tagAlreadyExists(String tagName) =>
      'Tag "$tagName" already exists or is invalid';

  @override
  String get deleteTag => 'Delete Tag';

  @override
  String confirmDeleteTag(String tag) =>
      'Are you sure you want to delete tag "$tag"?';

  @override
  String tagDeletedSuccessfully(String tag) =>
      'Tag "$tag" deleted successfully';

  @override
  String get failedToDeleteTag => 'Failed to delete tag';

  @override
  String get addTag => 'Add Tag';

  // Photo and File Management (New)
  @override
  String get photoNotFound => 'Photo not found';

  @override
  String get photoUpdatedSuccessfully => 'Photo updated successfully';

  @override
  String get photoFileNotFound => 'Photo file not found';

  @override
  String failedToSharePhoto(String error) => 'Failed to share photo: $error';

  @override
  String get photo => 'Photo';

  @override
  String get shareAsImageFile => 'Share as image file';

  @override
  String get pdf => 'PDF';

  @override
  String get convertToPdfOnePage => 'Convert to PDF (1 photo per page)';

  @override
  String get photoSharedSuccessfully => 'Photo shared successfully';

  @override
  String get failedToOpenLink => 'Failed to open link';

  // Tools and Features (New)
  @override
  String get plusExclusive => 'Plus Exclusive';

  @override
  String get convertToPdf => 'Convert to PDF';

  @override
  String get convertImagesToPdf => 'Convert images to PDF files';

  // Default Values and System (New)
  @override
  String get sharedImageDescription => 'Image shared from external app';

  @override
  String get sharedDocumentDescription => 'Document shared from external app';

  @override
  String get importedPdfFile => 'Imported PDF file';

  // Activity Log Descriptions (New)
  @override
  String get photoNoteSuccessfullySaved => 'Photo note successfully saved';

  @override
  String get photoNoteDeletedFromGallery =>
      'Photo note has been deleted from gallery';

  @override
  String get photoNameSuccessfullyUpdated => 'Photo name successfully updated';

  @override
  String get photoDetailsSuccessfullyUpdated =>
      'Photo details successfully updated';

  @override
  String get ebookNoteSuccessfullySaved => 'Ebook note successfully saved';

  @override
  String get ebookNoteDeletedFromGallery =>
      'Ebook note has been deleted from gallery';

  @override
  String get ebookNameSuccessfullyUpdated => 'Ebook name successfully updated';

  @override
  String get ebookDetailsSuccessfullyUpdated =>
      'Ebook details successfully updated';

  @override
  String get ebookTitleSuccessfullyUpdated =>
      'Ebook title successfully updated';

  @override
  String get photoPageNoteDeletedFromGallery =>
      'Photo page note has been deleted from gallery';

  @override
  String get photoPageNameSuccessfullyUpdated =>
      'Photo page name successfully updated';

  @override
  String get photoPageDetailsSuccessfullyUpdated =>
      'Photo page details successfully updated';

  // Folder View Feature
  @override
  String get folderView => 'Folder View';

  @override
  String get enableFolderView => 'Enable Folder View';

  @override
  String get disableFolderView => 'Disable Folder View';

  @override
  String get folderViewEnabled => 'Folder view enabled';

  @override
  String get folderViewDisabled => 'Folder view disabled';

  @override
  String get viewAsGrid => 'View as Grid';

  @override
  String get viewAsFolders => 'View as Folders';

  @override
  String folderPhotosCount(int count) => '$count photos';

  @override
  String get noPhotosInFolder => 'No photos in this folder';

  @override
  String get addPhotoToFolder => 'Add Photo to Folder';

  @override
  String get selectFolder => 'Select Folder';

  @override
  String get createNewFolder => 'Create New Folder';

  @override
  String get folderName => 'Folder Name';

  @override
  String get enterFolderName => 'Enter folder name';

  @override
  String get createFolder => 'Create Folder';

  @override
  String folderCreated(String name) => 'Folder "$name" created';

  @override
  String photoAddedToFolder(String folderName) =>
      'Photo added to "$folderName" folder';

  // Save To Phone Feature
  @override
  String get saveToPhone => 'Save To Phone';

  @override
  String get saveToPhoneDesc => 'Save to Documents/Yupiread';

  @override
  String get savingToDocuments => 'Saving to Documents...';

  @override
  String savingEbookToDocuments(String title) => 'Saving $title to Documents...';

  @override
  String savingMultipleEbooksToDocuments(int count) => 'Saving $count ebooks to Documents...';

  @override
  String get ebookSavedToDocuments => 'Ebook successfully saved to Documents/Yupiread';

  @override
  String get ebooksSavedToDocuments => 'Ebooks successfully saved to Documents/Yupiread';

  @override
  String get failedToSaveEbook => 'Failed to save ebook';

  @override
  String failedToSaveEbookError(String error) => 'Failed to save ebook: $error';

  @override
  String ebooksSavedSummary(int success, int total) => '$success of $total ebooks saved successfully';

  @override
  String ebooksSavedPartial(int success, int fail) => '$success successful, $fail failed to save';

  @override
  String get failedToSaveAllEbooks => 'Failed to save all ebooks';

  @override
  String get storagePermissionRequired => 'Storage Permission Required';

  @override
  String get storagePermissionMessage => 'This app needs storage permission to save ebooks to your device. Please grant storage permission in app settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get cannotAccessDocuments => 'Cannot access Documents folder';

  @override
  String get sourceFileNotFound => 'Source file not found';

  // Search Feature
  @override
  String get searchEbooks => 'Search ebooks...';

  @override
  String get searchPhotos => 'Search photos...';

  @override
  String get searchResults => 'Search Results';

  @override
  String get noSearchResults => 'No search results found';

  @override
  String searchResultsCount(int count) => '$count results found';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get searchHint => 'Type to search';
  
  // Additional Features
  @override
  String get additionalFeatures => 'Additional Features';

  @override
  String get showSearchBarInGallery => 'Show Search Bar in Gallery';

  @override
  String get showSearchBarInEbooks => 'Show Search Bar in Ebooks';

  @override
  String get searchBarVisibility => 'Search Bar Visibility';

  @override
  String get searchBarVisibilityDesc => 'Control when search bars are visible';

  @override
  String get searchBarEnabled => 'Search bar enabled';

  @override
  String get searchBarDisabled => 'Search bar disabled';

  // Multiple File Import
  @override
  String get importFiles => 'Import Files';

  @override
  String get importFilesDesc => 'PDF & Word files';

  @override
  String get processingFiles => 'Processing files...';

  @override
  String filesImportedSuccessfully(int count) => '$count files imported successfully';

  @override
  String get failedToImportAllFiles => 'Failed to import all files';

  @override
  String importSummary(int success, int fail) => '$success successful, $fail failed';

  @override
  String get noValidFilesSelected => 'No valid files selected';
}
