# Yupiread

Aplikasi Android untuk mengelola galeri foto dan ebook. Dirancang untuk kebutuhan edukasi dengan antarmuka yang sederhana.

## Apa yang bisa Anda lakukan

### Kelola foto dengan mudah
- Ambil foto langsung dari kamera atau galeri
- Scan dokumen otomatis dengan teknologi ML
- Atur foto dengan sistem tag
- Lihat foto dalam mode grid atau folder
- Bagikan foto dengan cepat

### Baca dan buat ebook
- Buka file PDF dan Word (.docx)
- Tulis ebook dengan editor rich text
- Lacak progress membaca otomatis
- Scan teks dari gambar
- Konversi foto ke PDF

### Pantau aktivitas baca
- Lihat streak harian membaca
- Cek total waktu baca
- Kelola tag personal
- Ganti tema (terang/gelap/sistem)

## Cara install

### Yang Anda butuhkan
- Flutter SDK 3.7.2 atau lebih baru
- Android Studio atau VS Code
- Device Android (API 21+)

### Langkah install
```bash
git clone <repository-url>
cd yupiread
flutter pub get
flutter run
```

### Build untuk rilis
```bash
flutter build apk --release
```

## Teknologi yang digunakan

### Framework
- Flutter 3.7.2
- Android (minSdk 21, targetSdk 34)
- Bahasa Indonesia dan Inggris

### Library utama
- `flutter_quill` - Editor rich text
- `extended_image` - Manajemen gambar
- `syncfusion_flutter_pdfviewer` - PDF viewer
- `google_mlkit_text_recognition` - OCR
- `cunning_document_scanner` - Document scanner
- `shared_preferences` - Penyimpanan data
- `image_picker` - Ambil foto

## Struktur project

```
lib/
├── models/     # Model data
├── screens/    # Layar UI (24 screens)
├── services/   # Logic bisnis
├── widgets/    # Komponen UI
└── main.dart   # Entry point
```

## Fitur lengkap

### Dashboard
- Ringkasan aktivitas terbaru
- Statistik cepat (streak, waktu baca)
- Foto dan ebook terbaru

### Galeri
- Tampilan grid dengan lazy loading
- Pilih multiple foto
- Filter berdasarkan tag
- Integrasi document scanner
- Mode folder view

### Ebook Reader
- Baca PDF dengan zoom dan navigasi
- Support dokumen Word
- Editor dengan toolbar lengkap
- Tracking progress otomatis
- Export ke PDF

### Profil
- Foto profil user
- Statistik membaca
- Kelola tag custom
- Pengaturan tema
- Pengaturan galeri

## Performa

- Cache gambar yang optimal
- Loading data efisien
- Cleanup file otomatis
- Database SQLite teroptimasi
- Manajemen memori yang baik

## Permission yang dibutuhkan

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## Update terbaru (v1.1.8)

- Folder view untuk galeri
- Scan dokumen yang lebih baik
- Tracking ebook yang diperbaiki
- Optimasi performa
- Perbaikan bug

## Kontribusi

1. Fork repository ini
2. Buat branch fitur (`git checkout -b feature/FiturBaru`)
3. Commit perubahan (`git commit -m 'Tambah FiturBaru'`)
4. Push ke branch (`git push origin feature/FiturBaru`)
5. Buat Pull Request

## Lisensi

MIT License. Lihat file `LICENSE` untuk detail.

## Link project

[https://github.com/Alpinnnn/yupiread](https://github.com/Alpinnnn/yupiread)

---

**Yupiread** - *Where Reality Comes Into Eternity* 
