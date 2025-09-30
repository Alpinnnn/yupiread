import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'pdf_compress_screen.dart';
import 'pdf_merge_screen.dart';
import 'image_to_pdf_screen.dart';
import 'pdf_scanner_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        l10n.tools,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.plusExclusive,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final tools = [
                      {
                        'icon': Icons.document_scanner,
                        'title': l10n.pdfScanner,
                        'description': l10n.pdfScannerDesc,
                        'color': const Color(0xFF8B5CF6),
                        'onTap': () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PdfScannerScreen(),
                            ),
                          );
                        },
                      },
                      {
                        'icon': Icons.compress,
                        'title': l10n.compressPdf,
                        'description': l10n.compressPdfDesc,
                        'color': const Color(0xFF3B82F6),
                        'onTap': () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PdfCompressScreen(),
                            ),
                          );
                        },
                      },
                      {
                        'icon': Icons.merge,
                        'title': l10n.mergePdf,
                        'description': l10n.mergePdfDesc,
                        'color': const Color(0xFF10B981),
                        'onTap': () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PdfMergeScreen(),
                            ),
                          );
                        },
                      },
                      {
                        'icon': Icons.picture_as_pdf,
                        'title': l10n.convertToPdf,
                        'description': l10n.convertImagesToPdf,
                        'color': const Color(0xFFEF4444),
                        'onTap': () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ImageToPdfScreen(),
                            ),
                          );
                        },
                      },
                    ];
                    
                    final tool = tools[index];
                    return _buildToolCard(
                      context: context,
                      icon: tool['icon'] as IconData,
                      title: tool['title'] as String,
                      description: tool['description'] as String,
                      color: tool['color'] as Color,
                      onTap: tool['onTap'] as VoidCallback,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).cardTheme.shadowColor ??
                  Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
