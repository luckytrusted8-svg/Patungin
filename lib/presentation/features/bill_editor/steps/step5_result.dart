import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../providers/bill_draft_controller.dart';

class Step5Result extends ConsumerStatefulWidget {
  const Step5Result({super.key});

  @override
  ConsumerState<Step5Result> createState() => _Step5ResultState();
}

class _Step5ResultState extends ConsumerState<Step5Result> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  String _buildShareText() {
    final state = ref.read(billDraftControllerProvider);
    final bill = state.toBill();
    final results = state.results;
    final settlements = state.settlements;

    final buffer = StringBuffer();
    buffer.writeln('🧾 *RINGKASAN PATUNGIN: ${bill.title}*');
    buffer.writeln('📅 ${DateFormatter.formatDateTime(bill.createdAt)}');
    buffer.writeln('--------------------------------');
    buffer.writeln('💰 *Total Tagihan:* ${MoneyFormatter.format(bill.total)}');
    if (bill.taxAmount > 0) {
      buffer.writeln('• Pajak: ${MoneyFormatter.format(bill.taxAmount)}');
    }
    if (bill.serviceAmount > 0) {
      buffer.writeln('• Service: ${MoneyFormatter.format(bill.serviceAmount)}');
    }
    if (bill.discountAmount > 0) {
      buffer.writeln('• Diskon: -${MoneyFormatter.format(bill.discountAmount)}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('👥 *RINCIAN PER ORANG:*');
    for (final r in results) {
      buffer.writeln('• *${r.name}:* ${MoneyFormatter.format(r.totalToPay)}');
      for (final item in r.itemDetails) {
        final portionText = item.portion > 1 ? ' (${item.portion}x)' : '';
        buffer.writeln('   - ${item.itemName}$portionText: ${MoneyFormatter.format(item.allocatedPrice)}');
      }
    }
    if (settlements.isNotEmpty) {
      buffer.writeln('--------------------------------');
      buffer.writeln('💸 *TRANSFER KE SIAPA:*');
      for (final s in settlements) {
        buffer.writeln('👉 *${s.fromName}* transfer ke *${s.toName}*: ${MoneyFormatter.format(s.amount)}');
      }
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('Dihitung dengan aplikasi *Patungin* 🤝');
    return buffer.toString();
  }

  Future<void> _shareText() async {
    final text = _buildShareText();
    await Share.share(text, subject: 'Rincian Patungin');
  }

  Future<void> _copyText() async {
    final text = _buildShareText();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.textCopied),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareImage() async {
    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/patungin_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Rincian Patungin: ${ref.read(billDraftControllerProvider).title}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan gambar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billDraftControllerProvider);
    final results = state.results;
    final settlements = state.settlements;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wrapper RepaintBoundary untuk Export Gambar
            RepaintBoundary(
              key: _repaintBoundaryKey,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Badge Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.calculate_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Patungin',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Rincian Patungan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Header Bill: Title & Total
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.title.isEmpty ? 'Tagihan Restoran' : state.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryLight,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormatter.formatDateTime(state.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Total Tagihan',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                            ),
                            Text(
                              MoneyFormatter.format(state.receiptTotal),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                  // Siapa Bayar ke Siapa
                  if (settlements.isNotEmpty) ...[
                    const Text(
                      AppStrings.whoPaysWhom,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...settlements.map((s) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_forward_rounded, color: AppColors.accent, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: s.fromName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(text: ' bayar ke '),
                                      TextSpan(
                                        text: s.toName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Text(
                                MoneyFormatter.format(s.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.dark,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Rincian per Orang
                  const Text(
                    AppStrings.personBreakdown,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...results.map((r) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  r.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  MoneyFormatter.format(r.totalToPay),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            // Item Breakdown
                            ...r.itemDetails.map((it) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${it.itemName}${it.portion > 1 ? ' (${it.portion}x)' : ''}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        MoneyFormatter.format(it.allocatedPrice),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                )),
                            if (r.taxShare > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Porsi Pajak', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                                    Text('+${MoneyFormatter.format(r.taxShare)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                                  ],
                                ),
                              ),
                            if (r.serviceShare > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Porsi Layanan', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                                    Text('+${MoneyFormatter.format(r.serviceShare)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                                  ],
                                ),
                              ),
                            if (r.discountShare > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Porsi Diskon', style: TextStyle(fontSize: 12, color: AppColors.success)),
                                    Text('-${MoneyFormatter.format(r.discountShare)}', style: const TextStyle(fontSize: 12, color: AppColors.success)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tombol-Tombol Aksi
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareText,
                  icon: const Icon(Icons.share, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'WhatsApp',
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareImage,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Gambar',
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: _copyText,
                icon: const Icon(Icons.copy_rounded, size: 20),
                tooltip: AppStrings.copyText,
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
}
