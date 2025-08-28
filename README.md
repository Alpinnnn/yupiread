# YupiRead

**Modern Education Gallery & Ebook App for Android**

YupiRead adalah aplikasi Android modern yang menggabungkan manajemen galeri foto dengan sistem ebook yang canggih. Dirancang khusus untuk kebutuhan edukasi dengan antarmuka yang bersih dan fitur-fitur produktif.

## Fitur Utama

### Galeri Foto
- **Foto Tunggal & Multi-Foto**: Kelola foto individual atau kumpulan foto dalam satu halaman
- **Pengambilan Foto**: Kamera langsung atau import dari galeri
- **Scan Dokumen**: Auto-detection dokumen dengan teknologi OpenCV
- **Sistem Tag**: Organisasi foto dengan tag yang dapat dikustomisasi
- **Edit & Share**: Edit metadata dan bagikan foto dengan mudah

### Sistem Ebook
- **Format Lengkap**: Dukungan PDF, Word (.docx), dan format JSON Delta
- **Rich Text Editor**: Editor WYSIWYG dengan flutter_quill
- **Progress Tracking**: Pelacakan kemajuan baca otomatis
- **Text Recognition**: Scan teks dari gambar menggunakan ML Kit
- **Reading Analytics**: Statistik waktu baca dan streak harian

### Profil & Analytics
- **Reading Streak**: Pelacakan konsistensi membaca harian
- **Statistik Baca**: Total waktu membaca dan aktivitas
- **Custom Tags**: Manajemen tag personal
- **Theme System**: Light, Dark, dan System theme
- **Activity Dashboard**: Log aktivitas lengkap

## Teknologi

### Framework & Platform
- **Flutter SDK**: ^3.7.2
- **Platform**: Android (minSdk 21, targetSdk 34)
- **Localization**: Indonesian & English

### Dependencies Utama
```yaml
# UI & Editor
flutter_quill: ^11.4.2
extended_image: ^8.2.0
image_cropper: ^9.1.0

# File Management
file_picker: ^10.3.2
syncfusion_flutter_pdfviewer: ^30.2.6
syncfusion_flutter_pdf: ^30.2.6

# Storage & Database
shared_preferences: ^2.2.2
sqflite: ^2.3.0
path_provider: ^2.1.1

# ML & Recognition
google_mlkit_text_recognition: ^0.15.0
cunning_document_scanner: ^1.3.0

# Utilities
image_picker: ^1.0.4
share_plus: ^11.1.0
docx_to_text: ^1.0.1
```

## Arsitektur

### Struktur Project
```
lib/
├── models/           # Data models (Photo, Ebook, Activity)
├── screens/          # UI screens (16 screens)
├── services/         # Business logic & data management
├── widgets/          # Reusable UI components
└── main.dart         # App entry point
```

### Pola Arsitektur
- **Singleton Pattern**: DataService untuk state management
- **Service Layer**: Pemisahan logic bisnis dan UI
- **Local Storage**: SharedPreferences + SQLite
- **Theme Management**: Real-time theme switching
- **File Management**: Optimized caching & cleanup

## Instalasi & Setup

### Prerequisites
- Flutter SDK ^3.7.2
- Android Studio / VS Code
- Android device/emulator (API 21+)

### Langkah Instalasi
```bash
# Clone repository
git clone <repository-url>
cd yupiread

# Install dependencies
flutter pub get

# Run app
flutter run
```

### Build Release
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

## Fitur Detail

### Dashboard
- Overview aktivitas terbaru
- Quick stats (streak, reading time)
- Recent photos dan ebooks

### Gallery Management
- Grid view dengan lazy loading
- Multi-selection untuk batch operations
- Tag filtering dan search
- Document scanner integration

### Ebook Reader
- PDF viewer dengan zoom & navigation
- Word document support
- Rich text editor dengan toolbar lengkap
- Progress tracking otomatis
- Export ke PDF

### Profile System
- User profile dengan foto
- Reading statistics
- Custom tag management
- Theme preferences
- Gallery settings

## UI/UX Features

- **Material Design 3**: Modern Android design language
- **Dark/Light Theme**: Automatic system theme detection
- **Responsive Layout**: Optimized untuk berbagai ukuran layar
- **Smooth Animations**: Transisi yang halus dan natural
- **Indonesian Localization**: UI dalam bahasa Indonesia

## Performance

- **Image Caching**: Optimized memory management
- **Lazy Loading**: Efficient data loading
- **File Cleanup**: Automatic cleanup unused files
- **Database Optimization**: SQLite dengan indexing
- **Memory Management**: Proper disposal pattern

## Permissions

```xml
<!-- Required permissions -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## Changelog

### Version 1.0.6
- Enhanced document scanning
- Improved ebook progress tracking
- Bug fixes dan performance improvements
- Theme system optimization

## Contributing

1. Fork repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Contact

Project Link: [https://github.com/username/yupiread](https://github.com/username/yupiread)

---

**YupiRead** - *Where Reality Comes Into Eternity* 
