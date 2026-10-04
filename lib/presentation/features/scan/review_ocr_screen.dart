import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../domain/models/bill_item.dart';
import '../../../domain/parser/number_parser.dart';
import '../../../domain/parser/parsed_receipt.dart';
import '../../providers/bill_draft_controller.dart';
import '../bill_editor/widgets/item_dialog.dart';

class ReviewOcrScreen extends ConsumerStatefulWidget {
  final ParsedReceipt parsedReceipt;
  final String? imagePath;

  const ReviewOcrScreen({
    super.key,
    required this.parsedReceipt,
    this.imagePath,
  });

  @override
  ConsumerState<ReviewOcrScreen> createState() => _ReviewOcrScreenState();
}

class _ReviewOcrScreenState extends ConsumerState<ReviewOcrScreen> {
  late List<ParsedItem> _items;
  int? _subtotal;
  int? _tax;
  int? _service;
  int? _discount;
  int? _total;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.parsedReceipt.items);
    _subtotal = widget.parsedReceipt.subtotal;
    _tax = widget.parsedReceipt.tax;
    _service = widget.parsedReceipt.service;
    _discount = widget.parsedReceipt.discount;
    _total = widget.parsedReceipt.total;
  }

  int get _itemsSum => _items.fold<int>(0, (sum, i) => sum + i.totalPrice);

  void _applyToDraft() {
    final updatedReceipt = ParsedReceipt(
      items: _items,
      subtotal: _subtotal ?? _itemsSum,
      tax: _tax,
      service: _service,
      discount: _discount,
      total: _total ?? (_itemsSum + (_tax ?? 0) + (_service ?? 0) - (_discount ?? 0)),
      rawText: widget.parsedReceipt.rawText,
      rawLines: widget.parsedReceipt.rawLines,
    );

    ref.read(billDraftControllerProvider.notifier).loadFromParsedReceipt(
          updatedReceipt,
          imagePath: widget.imagePath,
        );

    context.go(AppRoutes.billEditor);
  }

  void _addNewItem([String? initialName, int? initialPrice]) async {
    final billItemEquivalent = BillItem.create(
      id: 'temp',
      billId: 'temp',
      name: initialName ?? '',
      unitPrice: initialPrice ?? 0,
      quantity: 1,
      sortOrder: _items.length,
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ItemDialog(existingItem: billItemEquivalent),
    );

    if (result != null) {
      final name = result['name'] as String;
      final unitPrice = result['unitPrice'] as int;
      final quantity = result['quantity'] as int;

      setState(() {
        _items.add(
          ParsedItem(
            name: name,
            quantity: quantity,
            unitPrice: unitPrice,
            totalPrice: unitPrice * quantity,
            confidence: 1.0,
            rawText: name,
          ),
        );
      });
    }
  }

  void _addItemFromRawText(String rawLine) {
    final tokens = rawLine.trim().split(RegExp(r'\s+'));
    int? detectedPrice;
    String detectedName = rawLine;

    for (int k = tokens.length - 1; k >= 0; k--) {
      final price = NumberParser.parse(tokens[k]);
      if (price != null && price > 0) {
        detectedPrice = price;
        tokens.removeAt(k);
        detectedName = tokens.join(' ').trim();
        break;
      }
    }

    _addNewItem(
      detectedName.isNotEmpty ? detectedName : rawLine,
      detectedPrice ?? 0,
    );
  }

  void _editItem(int index) async {
    final item = _items[index];
    final billItemEquivalent = BillItem.create(
      id: 'temp',
      billId: 'temp',
      name: item.name,
      unitPrice: item.unitPrice,
      quantity: item.quantity,
      sortOrder: index,
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ItemDialog(existingItem: billItemEquivalent),
    );

    if (result != null) {
      setState(() {
        _items[index] = item.copyWith(
          name: result['name'] as String,
          unitPrice: result['unitPrice'] as int,
          quantity: result['quantity'] as int,
          totalPrice: (result['unitPrice'] as int) * (result['quantity'] as int),
          confidence: 1.0,
        );
      });
    }
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  List<String> _getDisplayRawLines() {
    if (widget.parsedReceipt.rawLines.isNotEmpty) {
      return widget.parsedReceipt.rawLines
          .map((l) => l.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }
    if (widget.parsedReceipt.rawText.isNotEmpty) {
      return widget.parsedReceipt.rawText
          .split('\n')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final isConsistent = _subtotal == null || _subtotal == _itemsSum;
    final diff = (_subtotal ?? _itemsSum) - _itemsSum;
    final rawLines = _getDisplayRawLines();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reviewOcrTitle),
        actions: [
          IconButton(
            tooltip: 'Tambah Item Manual',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _addNewItem(),
          ),
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _applyToDraft,
                child: const Text('Gunakan', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Banner Informasi Konsistensi Struk
          if (!isConsistent && _items.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.warning.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Subtotal struk (${MoneyFormatter.format(_subtotal!)}) berbeda dari jumlah item (${MoneyFormatter.format(_itemsSum)}). Selisih: ${MoneyFormatter.format(diff.abs())}. Silakan periksa item di bawah.',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          // Konten Utama
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Preview Foto Struk Asli (Jika ada)
                if (widget.imagePath != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.photo_outlined, size: 20, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text(
                                    'Foto Struk yang Dipindai',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Foto Ulang', style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(widget.imagePath!),
                              height: 190,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 2. KONDISI JIKA 0 ITEM TERDETEKSI (Solusi anti-bug layar putih)
                if (_items.isEmpty) ...[
                  Card(
                    color: AppColors.mintSoft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.primaryLight, width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.document_scanner_outlined,
                              size: 44,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Item Belum Terdeteksi Otomatis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Teks pada foto struk mungkin agak miring, terpotong, atau menggunakan tata letak khusus. Silakan tambahkan item manual di bawah atau ketuk teks yang terbaca.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondaryLight,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _addNewItem(),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Tambah Item Manual',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Foto Ulang',
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(64, 46),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. DAFTAR ITEM YANG BERHASIL DIBACA / DITAMBAHKAN
                if (_items.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Item Terdeteksi (${_items.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      TextButton.icon(
                        onPressed: () => _addNewItem(),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Tambah Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...List.generate(_items.length, (index) {
                    final item = _items[index];
                    final isLow = item.isLowConfidence;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isLow ? AppColors.warning.withValues(alpha: 0.05) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isLow ? AppColors.warning : AppColors.borderLight,
                          width: isLow ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            if (isLow)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  AppStrings.lowConfidenceBadge,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${item.quantity} × ${MoneyFormatter.format(item.unitPrice)}',
                          style: const TextStyle(color: AppColors.textSecondaryLight),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              MoneyFormatter.format(item.totalPrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _editItem(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                              onPressed: () => _deleteItem(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // 4. BAGIAN TEKS HASIL BACAAN KAMERA (RAW OCR LINES)
                if (rawLines.isNotEmpty) ...[
                  Card(
                    child: ExpansionTile(
                      initiallyExpanded: _items.isEmpty,
                      leading: const Icon(Icons.text_snippet_outlined, color: AppColors.primary),
                      title: const Text(
                        'Teks Hasil Scan Kamera (OCR)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        _items.isEmpty
                            ? 'Ketuk tombol "Ambil" pada baris di bawah untuk menjadikannya item'
                            : 'Lihat ${rawLines.length} baris teks yang terbaca dari kamera',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              ...rawLines.map((line) => Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundLight,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.borderLight),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            line,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () => _addItemFromRawText(line),
                                          icon: const Icon(Icons.add, size: 14),
                                          label: const Text('Ambil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(60, 32),
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            visualDensity: VisualDensity.compact,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom Bar Gunakan Hasil / Tambah Manual
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: const Border(
                  top: BorderSide(color: AppColors.borderLight),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, -3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_items.length} Item Terdaftar',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                        Text(
                          MoneyFormatter.format(_itemsSum),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_items.isNotEmpty)
                    FilledButton.icon(
                      onPressed: _applyToDraft,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Gunakan (${_items.length})',
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(140, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => _addNewItem(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Tambah Item',
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(140, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
