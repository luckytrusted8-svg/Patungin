import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../providers/bill_draft_controller.dart';

class Step4ExtraCosts extends ConsumerStatefulWidget {
  const Step4ExtraCosts({super.key});

  @override
  ConsumerState<Step4ExtraCosts> createState() => _Step4ExtraCostsState();
}

class _Step4ExtraCostsState extends ConsumerState<Step4ExtraCosts> {
  late final TextEditingController _taxNominalController;
  late final TextEditingController _serviceNominalController;
  late final TextEditingController _discountNominalController;
  late final TextEditingController _receiptTotalController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(billDraftControllerProvider);
    _taxNominalController = TextEditingController(
      text: state.taxAmount > 0 ? MoneyFormatter.formatRaw(state.taxAmount) : '',
    );
    _serviceNominalController = TextEditingController(
      text: state.serviceAmount > 0 ? MoneyFormatter.formatRaw(state.serviceAmount) : '',
    );
    _discountNominalController = TextEditingController(
      text: state.discountAmount > 0 ? MoneyFormatter.formatRaw(state.discountAmount) : '',
    );
    _receiptTotalController = TextEditingController(
      text: state.manualReceiptTotal != null
          ? MoneyFormatter.formatRaw(state.manualReceiptTotal!)
          : '',
    );
  }

  @override
  void dispose() {
    _taxNominalController.dispose();
    _serviceNominalController.dispose();
    _discountNominalController.dispose();
    _receiptTotalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billDraftControllerProvider);
    final controller = ref.read(billDraftControllerProvider.notifier);

    final diff = state.receiptTotal - state.calculatedTotal;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtotal Card
          Card(
            color: AppColors.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    AppStrings.subtotalLabel,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  Text(
                    MoneyFormatter.format(state.subtotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- PAJAK ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.receipt_outlined, size: 20, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            AppStrings.taxLabel,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Rp')),
                          ButtonSegment(value: true, label: Text('%')),
                        ],
                        selected: {state.isTaxPercent},
                        onSelectionChanged: (val) {
                          controller.setTaxMode(val.first);
                          if (!val.first) {
                            _taxNominalController.text =
                                MoneyFormatter.formatRaw(state.taxAmount);
                          }
                        },
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (state.isTaxPercent) ...[
                    Wrap(
                      spacing: 8,
                      children: [1000, 1100, 1200].map((bp) {
                        final isSel = state.taxPercent == bp;
                        return ChoiceChip(
                          label: Text('${bp ~/ 100}%'),
                          selected: isSel,
                          onSelected: (_) => controller.setTaxPercent(bp),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nominal: ${MoneyFormatter.format(state.taxAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ] else ...[
                    TextField(
                      controller: _taxNominalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '0',
                      ),
                      onChanged: (val) {
                        final parsed = MoneyFormatter.parse(val) ?? 0;
                        controller.setTaxNominal(parsed);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --- SERVICE CHARGE ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.room_service_outlined, size: 20, color: AppColors.accent),
                          SizedBox(width: 8),
                          Text(
                            AppStrings.serviceLabel,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Rp')),
                          ButtonSegment(value: true, label: Text('%')),
                        ],
                        selected: {state.isServicePercent},
                        onSelectionChanged: (val) {
                          controller.setServiceMode(val.first);
                          if (!val.first) {
                            _serviceNominalController.text =
                                MoneyFormatter.formatRaw(state.serviceAmount);
                          }
                        },
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (state.isServicePercent) ...[
                    Wrap(
                      spacing: 8,
                      children: [500, 700, 1000].map((bp) {
                        final isSel = state.servicePercent == bp;
                        return ChoiceChip(
                          label: Text('${bp ~/ 100}%'),
                          selected: isSel,
                          onSelected: (_) => controller.setServicePercent(bp),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nominal: ${MoneyFormatter.format(state.serviceAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ] else ...[
                    TextField(
                      controller: _serviceNominalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '0',
                      ),
                      onChanged: (val) {
                        final parsed = MoneyFormatter.parse(val) ?? 0;
                        controller.setServiceNominal(parsed);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --- DISKON ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.discount_outlined, size: 20, color: AppColors.success),
                          SizedBox(width: 8),
                          Text(
                            AppStrings.discountLabel,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Rp')),
                          ButtonSegment(value: true, label: Text('%')),
                        ],
                        selected: {state.isDiscountPercent},
                        onSelectionChanged: (val) {
                          controller.setDiscountMode(val.first);
                          if (!val.first) {
                            _discountNominalController.text =
                                MoneyFormatter.formatRaw(state.discountAmount);
                          }
                        },
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (state.isDiscountPercent) ...[
                    Wrap(
                      spacing: 8,
                      children: [500, 1000, 2000, 5000].map((bp) {
                        final isSel = state.discountPercent == bp;
                        return ChoiceChip(
                          label: Text('${bp ~/ 100}%'),
                          selected: isSel,
                          onSelected: (_) => controller.setDiscountPercent(bp),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nominal: ${MoneyFormatter.format(state.discountAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ] else ...[
                    TextField(
                      controller: _discountNominalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '0',
                      ),
                      onChanged: (val) {
                        final parsed = MoneyFormatter.parse(val) ?? 0;
                        controller.setDiscountNominal(parsed);
                      },
                    ),
                  ],
                  if (state.discountAmount > state.subtotal)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        AppStrings.discountExceedsSubtotal,
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- TOTAL DI STRUK & PERBANDINGAN ---
          Card(
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: diff != 0 ? AppColors.warning : AppColors.primary,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        AppStrings.calculatedTotalLabel,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        MoneyFormatter.format(state.calculatedTotal),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _receiptTotalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppStrings.receiptTotalLabel,
                      prefixText: 'Rp ',
                      hintText: MoneyFormatter.formatRaw(state.calculatedTotal),
                      helperText: 'Opsional: masukkan total yang tertera di struk fisik',
                    ),
                    onChanged: (val) {
                      final parsed = MoneyFormatter.parse(val);
                      controller.setReceiptTotal(parsed);
                    },
                  ),
                  if (diff != 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Terdapat selisih ${MoneyFormatter.format(diff.abs())} antara total struk dan rincian item.',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
