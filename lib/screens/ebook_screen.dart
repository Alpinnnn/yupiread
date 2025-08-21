import 'package:flutter/material.dart';

class EbookScreen extends StatelessWidget {
  const EbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ebook',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Koleksi ebook yang telah dibuat',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: _sampleEbooks.length,
                  itemBuilder: (context, index) {
                    return _buildEbookCard(context, _sampleEbooks[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEbookCard(BuildContext context, EbookData ebook) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: ebook.gradientColors,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Icon(
                    Icons.menu_book,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ebook.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${ebook.pageCount} halaman',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ebook.categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ebook.category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: ebook.categoryColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      ebook.lastRead,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: ebook.progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ebook.categoryColor,
                  ),
                  minHeight: 3,
                ),
                const SizedBox(height: 4),
                Text(
                  '${(ebook.progress * 100).toInt()}% selesai',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
            onSelected: (value) {
              // Handle menu selection
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'read',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow, size: 16),
                        SizedBox(width: 8),
                        Text('Baca'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 16),
                        SizedBox(width: 8),
                        Text('Bagikan'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  static final List<EbookData> _sampleEbooks = [
    EbookData(
      title: 'Catatan Kuliah Matematika Diskrit',
      pageCount: 45,
      category: 'Akademik',
      lastRead: '2 jam lalu',
      progress: 0.75,
      categoryColor: const Color(0xFF3B82F6),
      gradientColors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
    ),
    EbookData(
      title: 'Resep Masakan Favorit',
      pageCount: 28,
      category: 'Kuliner',
      lastRead: '1 hari lalu',
      progress: 0.45,
      categoryColor: const Color(0xFF10B981),
      gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
    ),
    EbookData(
      title: 'Panduan Desain UI/UX',
      pageCount: 67,
      category: 'Desain',
      lastRead: '3 hari lalu',
      progress: 0.30,
      categoryColor: const Color(0xFF8B5CF6),
      gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
    ),
    EbookData(
      title: 'Catatan Perjalanan Bali',
      pageCount: 23,
      category: 'Travel',
      lastRead: '1 minggu lalu',
      progress: 1.0,
      categoryColor: const Color(0xFFF59E0B),
      gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
    ),
    EbookData(
      title: 'Tutorial Programming Flutter',
      pageCount: 89,
      category: 'Programming',
      lastRead: '2 minggu lalu',
      progress: 0.60,
      categoryColor: const Color(0xFFEF4444),
      gradientColors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
    ),
    EbookData(
      title: 'Jurnal Harian 2024',
      pageCount: 156,
      category: 'Personal',
      lastRead: '3 minggu lalu',
      progress: 0.85,
      categoryColor: const Color(0xFF06B6D4),
      gradientColors: [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
    ),
  ];
}

class EbookData {
  final String title;
  final int pageCount;
  final String category;
  final String lastRead;
  final double progress;
  final Color categoryColor;
  final List<Color> gradientColors;

  EbookData({
    required this.title,
    required this.pageCount,
    required this.category,
    required this.lastRead,
    required this.progress,
    required this.categoryColor,
    required this.gradientColors,
  });
}
