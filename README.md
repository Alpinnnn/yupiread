# Yupiread

**Modern Education Gallery & Ebook App for Android**

Yupiread adalah aplikasi Android yang menggabungkan manajemen galeri foto dengan sistem ebook. Dirancang untuk kebutuhan edukasi dengan antarmuka yang bersih dan fitur manajemen konten.

## ✨ Fitur Utama

### 📸 Gallery System
- **Foto Individual & Photo Pages**: Kelola foto tunggal atau kumpulan foto dalam halaman terorganisir
- **Folder View Mode**: Toggle antara grid view dan folder view berdasarkan tag
- **Document Scanner**: Auto-detection dokumen dengan teknologi ML Kit
- **Smart Tagging**: Sistem tag yang dapat dikustomisasi
- **Batch Operations**: Multi-selection untuk operasi massal
- **Image Processing**: Crop, edit, dan share foto dengan mudah
- **Text Recognition**: Extract teks dari gambar menggunakan Google ML Kit

### 📚 Ebook Management
- **Multi-Format Support**: PDF, Word (.docx), dan Rich Text (JSON Delta)
- **Rich Text Editor**: Editor WYSIWYG dengan flutter_quill
- **PDF Reader**: Viewer dengan zoom dan navigation
- **Progress Tracking**: Pelacakan kemajuan baca otomatis
- **Text-to-Ebook**: Konversi teks hasil scan menjadi ebook
- **Export Features**: Export ke PDF dengan formatting

### 🛠️ PDF Tools (Plus Features)
- **PDF Compression**: Kompresi file PDF dengan berbagai level kualitas
- **PDF Merger**: Gabungkan multiple PDF menjadi satu file
- **Image to PDF**: Konversi gambar ke PDF dengan layout otomatis

### 📊 Dashboard & Analytics
- **Activity Dashboard**: Log aktivitas dengan lokalisasi
- **Reading Statistics**: Streak harian dan total waktu baca
- **Quick Stats**: Overview foto, ebook, dan aktivitas
- **User Profile**: Manajemen profil dan preferensi

### ☁️ Backup & Sync
- **Google Drive Integration**: Backup ke Google Drive
- **Data Export/Import**: Export/import data format ZIP
- **Progress Tracking**: Real-time backup/restore progress
- **Selective Backup**: Backup data selektif

## 🏗️ Arsitektur & Teknologi

### Framework & Platform
- **Flutter SDK**: ^3.7.2
- **Target Platform**: Android (minSdk 21, targetSdk 34)
- **Localization**: Indonesian & English

### Dependencies Utama
```yaml
# Core Framework
flutter: sdk
flutter_quill: ^11.4.2
extended_image: ^10.0.1

# File & Document Processing
syncfusion_flutter_pdfviewer: ^30.2.6
syncfusion_flutter_pdf: ^30.2.6
file_picker: ^10.3.2
docx_to_text: ^1.0.1
pdf_combiner: ^4.3.8
archive: 3.6.1

# ML & Computer Vision
google_mlkit_text_recognition: ^0.15.0
cunning_document_scanner: ^1.3.1
image_cropper: ^9.1.0

# Storage & Data Management
shared_preferences: ^2.2.2
path_provider: ^2.1.1

# Cloud & Networking
google_sign_in: ^6.2.1
googleapis: ^13.2.0
http: ^1.2.1

# UI & UX
reorderable_grid_view: ^2.2.8
image_picker: ^1.0.4
share_plus: ^11.1.0
url_launcher: ^6.3.0
```

### Struktur Project
```
lib/
├── models/
│   ├── photo_model.dart
│   ├── ebook_model.dart
│   └── activity_type.dart
├── screens/
│   ├── dashboard_screen.dart
│   ├── gallery_screen.dart
│   ├── ebook_screen.dart
│   ├── tools_screen.dart
│   └── [20+ other screens]
├── services/
│   ├── data_service.dart
│   ├── backup_service.dart
│   ├── theme_service.dart
│   └── [5+ other services]
├── l10n/
└── main.dart
```

### Pola Arsitektur
- **Singleton Pattern**: DataService untuk centralized state management
- **Service Layer Pattern**: Pemisahan business logic dari UI
- **Observer Pattern**: ChangeNotifier untuk reactive updates
- **Repository Pattern**: Data access abstraction
- **Clean Architecture**: Separation of concerns

## 🚀 Instalasi & Setup

### Prerequisites
- Flutter SDK ^3.7.2
- Android Studio / VS Code dengan Flutter extension
- Android device/emulator (API 21+)
- Git

### Langkah Instalasi
```bash
# Clone repository
git clone https://github.com/Alpinnnn/yupiread.git
cd yupiread

# Install dependencies
flutter pub get

# Check Flutter setup
flutter doctor

# Run in debug mode
flutter run

# Run in release mode
flutter run --release
```

### Build Production
```bash
# Build APK
flutter build apk --release --split-per-abi

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Install APK
flutter install --release
```

## 📱 Fitur Detail

### Dashboard Screen
- **Activity Timeline**: Log aktivitas dengan lokalisasi
- **Statistics Cards**: Total photos, ebooks, reading streak
- **Quick Actions**: Akses cepat ke fitur utama

### Gallery Management
- **Dual View Mode**: Grid view atau folder view berdasarkan tag
- **Smart Organization**: Auto-grouping berdasarkan tag
- **Advanced Search**: Filter berdasarkan tag, tanggal, nama
- **Batch Operations**: Multi-select untuk operasi massal
- **Document Scanner**: Scan dokumen dengan auto-crop
- **Photo Pages**: Kumpulan foto dalam halaman terorganisir

### Ebook System
- **Universal Reader**: Support PDF, DOCX, rich text
- **Progress Tracking**: Tracking progress untuk semua format
- **Rich Editor**: Text editor dengan formatting tools
- **Text Recognition**: Convert gambar ke teks
- **Export Options**: Save sebagai PDF
- **Reading Analytics**: Track waktu baca dan reading streak

### PDF Tools Suite
- **PDF Compression**: Multiple compression levels
- **PDF Merger**: Combine multiple PDFs
- **Image Converter**: Convert images ke PDF
- **Quality Control**: Preview sebelum save

### Backup & Cloud Sync
- **Google Drive Integration**: Backup ke Google Drive
- **Incremental Backup**: Backup perubahan saja
- **Selective Restore**: Restore data spesifik
- **Progress Monitoring**: Real-time progress

### Profile & Settings
- **User Management**: Profile dengan foto dan statistik
- **Theme System**: Light, Dark, System theme
- **Language Settings**: Indonesian dan English
- **Activity Controls**: Kontrol logging aktivitas
- **Gallery Settings**: Customize gallery behavior
- **Tag Management**: Kelola custom tags

## 🎨 UI/UX Features

### Design System
- **Material Design 3**: Android design guidelines
- **Dynamic Colors**: Adaptive color system
- **Responsive Layout**: Support semua ukuran layar
- **Smooth Animations**: 60fps transitions
- **Accessibility**: Screen readers dan high contrast

### Localization
- **Comprehensive i18n**: 200+ localized strings
- **Context-Aware**: Smart pluralization
- **Real-time Switching**: Change language tanpa restart
- **Fallback System**: Handle missing translations

### Performance Optimizations
- **Image Caching**: Memory management dengan LRU cache
- **Lazy Loading**: On-demand loading
- **File Management**: Automatic cleanup
- **Database Optimization**: Indexed queries
- **Memory Management**: Proper disposal patterns

## 🔒 Security & Permissions

### Required Permissions
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
```

### Privacy Features
- **Local Storage**: Data disimpan lokal
- **Optional Cloud**: Backup Google Drive optional
- **No Analytics**: Tidak ada tracking third-party
- **Secure Authentication**: OAuth 2.0 Google Drive

## 🔧 Development

### Code Quality
- **Linting**: Strict analysis_options
- **Architecture**: Clean code principles
- **Error Handling**: Comprehensive error handling
- **Testing**: Unit tests core logic
- **Documentation**: Inline documentation

### Performance Metrics
- **App Size**: ~50MB (split APKs)
- **Memory Usage**: <100MB average
- **Startup Time**: <2 seconds cold start
- **Battery Optimization**: Minimal background processing

## 📋 Platform Support

- **Minimum SDK**: Android 5.0 (API 21)
- **Target SDK**: Android 14 (API 34)
- **Architecture**: ARM64, ARMv7, x86_64
- **Screen Sizes**: Phone, Tablet, Foldable support

## 🤝 Contributing

1. Fork repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Follow coding standards
4. Add tests untuk new features
5. Update documentation
6. Commit changes (`git commit -m 'Add AmazingFeature'`)
7. Push to branch (`git push origin feature/AmazingFeature`)
8. Open Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

## 📞 Contact & Support

- **GitHub**: [https://github.com/Alpinnnn/yupiread](https://github.com/Alpinnnn/yupiread)
- **Issues**: Report bugs atau request features
- **Discussions**: Community discussions

---

**Yupiread v1.1.8** - *Where Reality Comes Into Eternity* 
