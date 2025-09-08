import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    switch (locale.languageCode) {
      case 'id': return Future.value(AppLocalizationsId());
      case 'en': return Future.value(AppLocalizationsEn());
    }
    return Future.value(AppLocalizationsEn());
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id')
  ];

  // App Title
  String get appTitle => 'Yupiread';

  // Navigation
  String get dashboard => 'Dashboard';
  String get gallery => 'Gallery';
  String get ebooks => 'Ebooks';
  String get profile => 'Profile';

  // Common Actions
  String get save => 'Save';
  String get cancel => 'Cancel';
  String get delete => 'Delete';
  String get edit => 'Edit';
  String get share => 'Share';
  String get add => 'Add';
  String get search => 'Search';
  String get settings => 'Settings';

  // Profile Screen
  String get appSettings => 'App Settings';
  String get languageSettings => 'Language Settings';
  String get themeSettings => 'Theme Settings';
  String get activitySettings => 'Activity Settings';
  String get selectLanguage => 'Select Language';
  String get currentLanguage => 'Current Language';

  // Shared Files
  String get sharedImage => 'Shared Image';
  String get whatToDoWithImage => 'What would you like to do with this image?';
  String get addToGallery => 'Add to Gallery';
  String get scanText => 'Scan Text';
  String get imageAddedToGallery => 'Image successfully added to gallery';
  String get documentAddedAndOpened => 'Document successfully added and opened';
  String get documentOpenedWith => 'Document successfully opened with Yupiread';
  String get failedToAddDocument => 'Failed to add document';

  // Text Recognition
  String get textScanner => 'Text Recognition';
  String get textRecognitionTitle => 'Text Recognition';
  String get scanningText => 'Scanning Text';
  String get extractingText => 'Extracting Text';
  String get activityDescPhotoPageCreated => 'Photo page created';
  String get activityDescPhotoPageUpdated => 'Photo page updated';
  String get activityDescPhotoPageDeleted => 'Photo page deleted';
  String get extractText => 'Extract Text';
  String get technicalInfo => 'Technical Info';
  String get resolution => 'Resolution';
  String get fileSize => 'File Size';
  String get enterEditTextHere => 'Enter edit text here';
  String get saving => 'Saving';
  String get scannedImage => 'Scanned Image';
  String get saveToGallery => 'Save to Gallery';
  String get scanResults => 'Scan Results';
  String get noInternetConnection => 'No internet connection';
  String errorOccurredWith(String error) => 'An error occurred: $error';
  String get editScannedText => 'Edit scanned text...';
  String get imageAndTextSaved => 'Image and text successfully saved to gallery';
  String get failedToSaveToGallery => 'Failed to save to gallery';
  String get textRecognitionFailed => 'Text recognition failed';
  String get noTextDetected => 'No text detected';
  String get textExtractionFailed => 'Failed to extract text: ';

  // Dashboard
  String get welcomeBack => 'Welcome Back';
  String get recentActivity => 'Recent Activity';
  String get quickActions => 'Quick Actions';
  String get takePhoto => 'Take Photo';
  String get scanDocument => 'Scan Document';
  String get addEbook => 'Add Ebook';
  String get viewGallery => 'View Gallery';
  String get statistics => 'Statistics';
  String get totalPhotos => 'Total Photos';
  String get totalEbooks => 'Total Ebooks';
  String get totalActivities => 'Total Activities';
  String get days => 'days';
  String get consecutive => 'consecutive';

  // Gallery
  String get myGallery => 'My Gallery';
  String get photos => 'Photos';
  String get photoPages => 'Photo Pages';
  String get createPhotoPage => 'Create Photo Page';
  String get noPhotosYet => 'No photos yet';
  String get addFirstPhoto => 'Add your first photo';
  String get sortBy => 'Sort by';
  String get filterByTag => 'Filter by tag';
  String get allTags => 'All Tags';
  String get addPhoto => 'Add Photo';
  String get newNote => 'New Note';
  String get failedToLoad => 'Failed to load';
  String get addPhotoNote => 'Add Photo Note';

  // Gallery Screen Specific
  String get photoTitle => 'Photo Title';
  String get descriptionOptional => 'Description (Optional)';
  String get selectTagsOptional => 'Select Tags (Optional):';
  String get failedToSavePhoto => 'Failed to save photo';
  String photoAddedSuccessfully(String title) => 'Photo "$title" successfully added';
  String get selectSaveMethod => 'Select Save Method';
  String documentsScannedCount(int count) => '$count documents successfully scanned.';
  String get multiDocumentPage => 'Multi-Document Page';
  String get multiDocumentPageDesc => 'All documents in one swipeable page';
  String get separateDocuments => 'Separate Documents';
  String get separateDocumentsDesc => 'Each document as separate item in gallery';
  String get noTagsAvailableForFilter => 'No tags available for filter yet';
  String get filterByTags => 'Filter by Tags';
  String get reset => 'Reset';
  String get deletePhotoTitle => 'Delete Photo';
  String deletePhotoMessage(String title) => 'Are you sure you want to delete "$title"?';

  // Ebooks
  String get myEbooks => 'My Ebooks';
  String get addNewEbook => 'Add New Ebook';
  String get noEbooksYet => 'No ebooks yet';
  String get addFirstEbook => 'Add your first ebook';
  String get recentlyRead => 'Recently Read';
  String get favorites => 'Favorites';
  String get importEbook => 'Import Ebook';
  String get readAction => 'Read';
  String get editAction => 'Edit';
  String get deleteAction => 'Delete';
  String get myActivity => 'My Activity';
  String get streakLabel => 'Streak';
  String get readingTimeLabel => 'Reading Time';
  String get totalReading => 'Total reading';
  String get readingStreakLabel => 'Reading Streak';
  String get viewAll => 'View All';
  String get noActivityYet => 'No activity yet';
  String get allActivities => 'All Activities';
  String get editProfile => 'Edit Profile';
  String get changeProfilePhoto => 'Change Profile Photo';
  String get enterUsername => 'Enter username';
  String get username => 'Username';
  String get languageChanged => 'Language Changed';
  String get restartAppMessage => 'Please restart the app to apply the new language setting';
  String get ok => 'OK';
  String get maxCharacters => 'Maximum 10 characters';
  String get usernameMaxError => 'Username cannot be more than 10 characters';
  String get cancelAction => 'Cancel';
  String get importPdfOrWord => 'Import PDF or Word files to start reading';
  String get cameraOption => 'Camera';
  String get galleryOption => 'Galeri';
  String get profileUpdated => 'Profil berhasil diperbarui';
  String get profilePhotoUpdated => 'Profile photo updated successfully';
  String get failedToUpdatePhoto => 'Failed to update profile photo';
  String get deleteAllData => 'Delete All Data';
  String get deletingData => 'Deleting data...';
  String get allDataDeleted => 'All data deleted successfully';
  String get failedToDeleteData => 'Failed to delete data';
  String get pdfFile => 'PDF File';
  String get importPdfDocument => 'Import PDF document';
  String get wordFile => 'Word File';
  String get importWordDocument => 'Import Word document';
  String get textEbook => 'Text Ebook';
  String get createNewTextEbook => 'Create new text ebook';
  String get failedToImportPdf => 'Failed to import PDF file';
  String get convertingWordToPdf => 'Converting Word to PDF...';
  String get failedToConvertWord => 'Failed to convert Word to PDF';
  String get failedToImportWord => 'Failed to import Word file';

  // Activity Log Messages
  String photoAdded(String title) => 'Photo "$title" added';
  String get photoAddedDesc => 'New photo note successfully saved';
  String photoDeleted(String title) => 'Photo "$title" deleted';
  String get photoDeletedDesc => 'Photo note has been deleted from gallery';
  String photoRenamed(String oldTitle, String newTitle) => 'Photo "$oldTitle" renamed to "$newTitle"';
  String get photoRenamedDesc => 'Photo name successfully updated';
  String photoEdited(String title) => 'Photo "$title" edited';
  String get photoEditedDesc => 'Photo details successfully updated';
  String ebookAdded(String title) => 'Ebook "$title" added';
  String get ebookAddedDesc => 'New ebook note successfully saved';
  String ebookDeleted(String title) => 'Ebook "$title" deleted';
  String get ebookDeletedDesc => 'Ebook note has been deleted from gallery';
  String ebookRenamed(String oldTitle, String newTitle) => 'Ebook "$oldTitle" renamed to "$newTitle"';
  String get ebookRenamedDesc => 'Ebook name successfully updated';
  String ebookEdited(String title) => 'Ebook "$title" edited';
  String get ebookEditedDesc => 'Ebook details successfully updated';
  String photoPageAdded(String title) => 'Photo page "$title" added';
  String photoPageAddedDesc(int count) => 'Photo page with $count photos successfully saved';
  String photoPageDeleted(String title) => 'Photo page "$title" deleted';
  String get photoPageDeletedDesc => 'Photo page note has been deleted from gallery';
  String photoPageRenamed(String oldTitle, String newTitle) => 'Photo page "$oldTitle" renamed to "$newTitle"';
  String get photoPageRenamedDesc => 'Photo page name successfully updated';
  String photoPageEdited(String title) => 'Photo page "$title" edited';
  String get photoPageEditedDesc => 'Photo page details successfully updated';


  // Profile
  String get myProfile => 'My Profile';
  String get accountSettings => 'Account Settings';
  String get dataManagement => 'Data Management';
  String get aboutApp => 'About App';
  String get version => 'Version';
  String get developer => 'Developer';

  // Messages
  String get success => 'Success';
  String get error => 'Error';
  String get loading => 'Loading...';
  String get noData => 'No data available';
  
  // Document Scanner
  String get scanFromCamera => 'Scan from Camera';
  String get scanFromGallery => 'Scan from Gallery';
  String get scanWithCamera => 'Scan with Camera';
  String get selectFromGallery => 'Select from Gallery';
  String get autoDetectEdges => 'Auto detect document edges in real-time';
  String get cropFromExisting => 'Crop document from existing photos';
  String get scannedFromCamera => 'Document Scanned from Camera';
  String get scannedFromGallery => 'Document Scanned from Gallery';
  String get photoFromGallery => 'Photo from Gallery';
  
  // Bottom Menu Actions
  String get editPhoto => 'Edit Photo';
  String get editPhotoPage => 'Edit Photo Page';
  String get deletePhoto => 'Delete Photo';
  String get deletePhotoPage => 'Delete Photo Page';
  String get deleteConfirmation => 'Are you sure you want to delete';
  String get deletePhotoConfirmation => 'Are you sure you want to delete this photo?';
  String get deletePhotoPageConfirmation => 'Are you sure you want to delete this photo page?';

  // Theme Settings
  String get selectTheme => 'Select Theme';
  String get followSystem => 'Follow System';
  String get followSystemDesc => 'Theme will follow device system settings';
  String get lightTheme => 'Light Theme';
  String get lightThemeDesc => 'Display with light background';
  String get darkTheme => 'Dark Theme';
  String get darkThemeDesc => 'Display with dark background';
  String get apply => 'Apply';
  String get light => 'Light';
  String get dark => 'Dark';
  String get system => 'Follow System';

  // Common Error Messages
  String get errorOccurred => 'An error occurred';
  String get tryAgain => 'Try Again';
  String get noDataAvailable => 'No data available';
  String get fileNotFound => 'File not found';
  String get accessDenied => 'Access denied';
  String get fileInUse => 'File is in use';
  String get fileSystemError => 'File system error';
  String get invalidDataFormat => 'Invalid data format';
  String get connectionError => 'Cannot connect to internet';
  String errorMessage(String error) => 'An error occurred: $error';

  // Default Tags
  String get tagNotes => 'Notes';
  String get tagImportant => 'Important';
  String get tagTasks => 'Tasks';
  String get tagIdeas => 'Ideas';
  String get tagReference => 'Reference';
  String get defaultUser => 'User';

  // Shared Files
  String get sharedImageDesc => 'Image shared from external app';
  String get sharedDocumentDesc => 'Document shared from external app';

  // Text Reader
  String get readerSettings => 'Reader Settings';
  String get fontSize => 'Font Size: ';
  String get darkMode => 'Dark Mode';
  String get close => 'Close';
  String get textCopiedToClipboard => 'Text successfully copied to clipboard';
  String get textReader => 'Text Reader';
  String get copyText => 'Copy Text';
  String get back => 'Back';
  String get readingFailed => 'Failed to read file: ';

  // Text to Ebook Editor
  String get ebookFromText => 'Ebook from Text';
  String extractingTextFromImages(int count) => 'Extracting text from $count images...';
  String get noTextExtracted => 'No text was successfully extracted from images';
  String get textExtractedSuccess => 'Text successfully extracted! You can edit it before saving.';
  String extractionFailed(String error) => 'Failed to extract text: $error';
  String get selectTags => 'Select Tags';
  String get done => 'Done';
  String get ebookTitleRequired => 'Ebook title cannot be empty';
  String get textContentRequired => 'Text content cannot be empty';
  String get ebookSavedSuccess => 'Ebook successfully saved!';
  String ebookSaveFailed(String error) => 'Failed to save ebook: $error';
  String get editEbook => 'Edit Ebook';
  String get createEbookFromText => 'Create Ebook from Text';
  String get saveEbook => 'Save Ebook';
  String get ebookTitle => 'Ebook Title';
  String tagsCount(int count) => 'Tags ($count)';
  String get textContent => 'Text Content';

  // Text Recognition
  String pageNumber(int page) => '--- Page $page ---';

  // Tools Settings
  String get toolsSettings => 'Tools Settings';
  String get alwaysShowToolSection => 'Always Show Tool Section';
  String get toolsSectionDesc => 'Show Tools tab in bottom navigation';
  String get tools => 'Tools';
  String get compressPdf => 'Compress PDF';
  String get mergePdf => 'Merge PDF';
  String get compressPdfDesc => 'Compress PDF files to reduce size';
  String get mergePdfDesc => 'Merge multiple PDF files into one';
  String get selectPdfsToCompress => 'Select PDFs to Compress';
  String get selectPdfsToMerge => 'Select PDFs to Merge';
  String get addFromFileManager => 'Add from File Manager';
  String get compressing => 'Compressing...';
  String get merging => 'Merging...';
  String get compressionComplete => 'Compression completed successfully';
  String get mergeComplete => 'Merge completed successfully';
  String get compressionFailed => 'Compression failed';
  String get mergeFailed => 'Merge failed';
  String get selectAtLeastOnePdf => 'Please select at least one PDF';
  String get selectAtLeastTwoPdfs => 'Please select at least two PDFs to merge';
  String get noPdfsAvailable => 'No PDF files available';
  String get addPdfsFirst => 'Add some PDF files first';
  String get compress => 'Compress';
  String get merge => 'Merge';
  String get pdfTools => 'Tools';
  String pdfsSelected(int count) => '$count PDFs selected';
  String get selectAll => 'Select All';
  String get deselectAll => 'Deselect All';

  // Language Selection Dialog
  String get selectLanguageTitle => 'Select Language';
  String get indonesianLanguage => 'Bahasa Indonesia';
  String get englishLanguage => 'English';
  String get indonesianLanguageDesc => 'Use Indonesian language for the app';
  String get englishLanguageDesc => 'Use English language for the app';
  String get languageChangedSuccess => 'Language changed successfully';
  String get languageChangedTitle => 'Language Changed Successfully';
  String get restartAppRequired => 'The app needs to be restarted to apply the language changes.';

  // Profile Screen
  String get managementSetting => 'Management Setting';
  String get appSetting => 'App Setting';
  String get tagSetting => 'Tag Setting';
  String get gallerySetting => 'Gallery Setting';
  String get ebookSetting => 'Ebook Setting';
  String get languageSettingsProfile => 'Language Settings';
  String get themeSetting => 'Theme Setting';
  String get activitySettingsProfile => 'Activity Settings';
  String get removeData => 'Remove Data';
  String get cropProfilePhoto => 'Crop Profile Photo';
  String get profilePhotoUpdatedSuccess => 'Profile photo updated successfully';
  String get failedToUpdateProfilePhoto => 'Failed to update profile photo';
  String get themeChangedTo => 'Theme changed to';
  String get toolsSectionEnabled => 'Tools section enabled';
  String get toolsSectionDisabled => 'Tools section disabled';
  String get removeAllData => 'Remove All Data';
  String get removeDataConfirmation => 'Are you sure you want to remove all app data? This action cannot be undone and will delete:\n\n• All photos and notes\n• All ebooks and reading progress\n• Activity history\n• Profile settings\n• Custom tags\n\nThe app will start fresh.';
  String get removeAll => 'Remove All';
  String get removingData => 'Removing data...';
  String get allDataRemoved => 'All data successfully removed';
  String get failedToRemoveData => 'Failed to remove data';

  // Gallery Screen Additional Localization
  String get failedToSelectPhoto => 'Failed to select photo';
  String get selectAddMethod => 'Select Add Method';
  String youSelected(int count) => 'You selected $count photos. How would you like to add them?';
  String get separatePhotos => 'Separate Photos';
  String get separatePhotosDesc => 'Each photo as separate item in gallery';
  String get multiPhoto => 'Multi-Photo';
  String addPhotosCount(int count) => 'Add $count Photos';
  String get titlePrefix => 'Title Prefix (will add number)';
  String get descriptionOptionalShort => 'Description (optional)';
  String get tagsOptional => 'Tags (optional):';
  String get newTagsComma => 'New tags (separate with comma)';
  String get saveAll => 'Save All';
  String get createPhotoPageTitle => 'Create Photo Page';
  String photosSelected(int count) => '$count photos selected';
  String get pageTitle => 'Page Title';
  String get createPage => 'Create Page';
  String photosAddedSuccessfully(int count) => '$count photos successfully added';
  String photoPageCreatedSuccess(String title, int count) => 'Photo page "$title" successfully created with $count photos';
  String photoDeletedSuccess(String title) => 'Photo "$title" successfully deleted';
  String failedToSavePhotoError(String error) => 'Failed to save photo: $error';
  String failedToSelectPhotoError(String error) => 'Failed to select photo: $error';
  String failedToAddPhotosError(String error) => 'Failed to add photos: $error';
  String get multiPhotoPageTitle => 'Multi-Photo Page';
  String get multiPhotoPageDesc => 'All photos in one page that can be swiped';
  String get photoPage => 'Photo Page';

  // Backup & Restore
  String get backupRestore => 'Backup & Restore';
  String get backup => 'Backup';
  String get restore => 'Restore';
  String get googleDrive => 'Google Drive';
  String get signInToGoogleDrive => 'Sign In to Google Drive';
  String get signOutFromGoogleDrive => 'Sign Out from Google Drive';
  String get connectedAs => 'Connected as';
  String get notConnectedToGoogleDrive => 'Not connected to Google Drive';
  String get createBackup => 'Create Backup';
  String get backupList => 'Backup List';
  String get noBackupsYet => 'No backups yet';
  String get createFirstBackup => 'Create your first backup';
  String get backupSuccessful => 'Backup successful';
  String get backupFailed => 'Backup failed';
  String get restoreSuccessful => 'Restore successful';
  String get restoreFailed => 'Restore failed';
  String get deleteBackup => 'Delete Backup';
  String get confirmRestore => 'Confirm Restore';
  String get confirmRestoreMessage => 'Are you sure you want to restore data from this backup?\n\nAll current data will be replaced with backup data.';
  String get confirmDeleteBackup => 'Are you sure you want to delete this backup?';
  String get backupDeleted => 'Backup successfully deleted';
  String get failedToDeleteBackup => 'Failed to delete backup';
  String get failedToLoadBackups => 'Failed to load backup list';
  String get signInSuccessful => 'Successfully signed in to Google Drive';
  String get signInFailed => 'Failed to sign in to Google Drive';
  String get signOutSuccessful => 'Successfully signed out from Google Drive';
  String get pleaseSignInFirst => 'Please sign in to Google Drive first';
  String get refreshing => 'Refreshing...';
  String get autoBackup => 'Auto Backup';
  String get autoBackupInterval => 'Auto Backup Interval';
  String get enableAutoBackup => 'Enable Auto Backup';
  String get selectInterval => 'Select Interval';
  String get daily => 'Daily';
  String get weekly => 'Weekly';
  String get monthly => 'Monthly';
  String get autoBackupEnabled => 'Auto backup enabled';
  String get autoBackupDisabled => 'Auto backup disabled';
  String get daysAgo => 'days ago';
  String get hoursAgo => 'hours ago';
  String get minutesAgo => 'minutes ago';
  String get justNow => 'Just now';
  String get signInToViewBackups => 'Sign in to Google Drive to view backups';
  String get backingUp => 'Backing up...';

  // Folder View Feature
  String get folderView => 'Folder View';
  String get enableFolderView => 'Enable Folder View';
  String get disableFolderView => 'Disable Folder View';
  String get folderViewEnabled => 'Folder view enabled';
  String get folderViewDisabled => 'Folder view disabled';
  String get viewAsGrid => 'View as Grid';
  String get viewAsFolders => 'View as Folders';
  String folderPhotosCount(int count) => '$count photos';
  String get noPhotosInFolder => 'No photos in this folder';
  String get addPhotoToFolder => 'Add Photo to Folder';
  String get selectFolder => 'Select Folder';
  String get createNewFolder => 'Create New Folder';
  String get folderName => 'Folder Name';
  String get enterFolderName => 'Enter folder name';
  String get createFolder => 'Create Folder';
  String folderCreated(String name) => 'Folder "$name" created';
  String photoAddedToFolder(String folderName) => 'Photo added to "$folderName" folder';
  String get signOut => 'Sign Out';

  // Development Section
  String get development => 'Development';
  String get supportDevelopment => 'Support Development';
  String get githubRepository => 'GitHub Repository';

  // Update Dialog
  String get updateAvailable => 'Update Available';
  String get updateLater => 'Later';
  String get updateNow => 'Update';

  // Common Actions and Messages (New)
  String get finished => 'Finished';
  String get goBack => 'Go Back';
  String get saveDocument => 'Save Document';
  String get updateDocument => 'Update Document';
  String get createNewEbook => 'Create New Ebook';
  String get newEbook => 'New Ebook';
  String get documentSavedSuccessfully => 'Document saved successfully';
  String get documentUpdatedSuccessfully => 'Document updated successfully';
  String get ebookNotFound => 'Ebook not found';
  String get editTags => 'Edit Tags';

  // Tag Management (New)
  String get tagSettings => 'Tag Settings';
  String get addNewTag => 'Add New Tag';
  String get tagList => 'Tag List';
  String get availableTags => 'Available Tags';
  String get noTagsAvailable => 'No tags available';
  String get addTagsToOrganize => 'Add tags to organize your photos and ebooks';
  String get tagNameEmpty => 'Tag name cannot be empty';
  String tagAddedSuccessfully(String tagName) => 'Tag "$tagName" added successfully';
  String tagAlreadyExists(String tagName) => 'Tag "$tagName" already exists or is invalid';
  String get deleteTag => 'Delete Tag';
  String confirmDeleteTag(String tag) => 'Are you sure you want to delete tag "$tag"?';
  String tagDeletedSuccessfully(String tag) => 'Tag "$tag" deleted successfully';
  String get failedToDeleteTag => 'Failed to delete tag';
  String get addTag => 'Add Tag';

  // Photo and File Management (New)
  String get photoNotFound => 'Photo not found';
  String get photoUpdatedSuccessfully => 'Photo updated successfully';
  String get photoFileNotFound => 'Photo file not found';
  String failedToSharePhoto(String error) => 'Failed to share photo: $error';
  String get photo => 'Photo';
  String get shareAsImageFile => 'Share as image file';
  String get pdf => 'PDF';
  String get convertToPdfOnePage => 'Convert to PDF (1 photo per page)';
  String get photoSharedSuccessfully => 'Photo shared successfully';
  String get failedToOpenLink => 'Failed to open link';

  // Tools and Features (New)
  String get plusExclusive => 'Plus Exclusive';
  String get convertToPdf => 'Convert to PDF';
  String get convertImagesToPdf => 'Convert images to PDF files';

  // Default Values and System (New)
  String get sharedImageDescription => 'Image shared from external app';
  String get sharedDocumentDescription => 'Document shared from external app';
  String get importedPdfFile => 'Imported PDF file';

  // Activity Log Descriptions (New)
  String get photoNoteSuccessfullySaved => 'Photo note successfully saved';
  String get photoNoteDeletedFromGallery => 'Photo note has been deleted from gallery';
  String get photoNameSuccessfullyUpdated => 'Photo name successfully updated';
  String get photoDetailsSuccessfullyUpdated => 'Photo details successfully updated';
  String get ebookNoteSuccessfullySaved => 'Ebook note successfully saved';
  String get ebookNoteDeletedFromGallery => 'Ebook note has been deleted from gallery';
  String get ebookNameSuccessfullyUpdated => 'Ebook name successfully updated';
  String get ebookDetailsSuccessfullyUpdated => 'Ebook details successfully updated';
  String get ebookTitleSuccessfullyUpdated => 'Ebook title successfully updated';
  String get photoPageNoteDeletedFromGallery => 'Photo page note has been deleted from gallery';
  String get photoPageNameSuccessfullyUpdated => 'Photo page name successfully updated';
  String get photoPageDetailsSuccessfullyUpdated => 'Photo page details successfully updated';
}
