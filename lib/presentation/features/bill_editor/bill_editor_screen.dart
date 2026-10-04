import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/bill_draft_controller.dart';
import '../../providers/database_provider.dart';
import 'steps/step1_items.dart';
import 'steps/step2_participants.dart';
import 'steps/step3_assign.dart';
import 'steps/step4_extra_costs.dart';
import 'steps/step5_result.dart';

class BillEditorScreen extends ConsumerStatefulWidget {
  const BillEditorScreen({super.key});

  @override
  ConsumerState<BillEditorScreen> createState() => _BillEditorScreenState();
}

class _BillEditorScreenState extends ConsumerState<BillEditorScreen> {
  bool _isSaving = false;

  static const _steps = [
    AppStrings.stepItems,
    AppStrings.stepParticipants,
    AppStrings.stepAssign,
    AppStrings.stepExtraCosts,
    AppStrings.stepResult,
  ];

  bool _validateStep(BuildContext context, BillDraftState state) {
    switch (state.currentStep) {
      case 0:
        if (state.items.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tambahkan minimal 1 item terlebih dahulu.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      case 1:
        if (state.participants.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.minParticipantsWarning),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      case 2:
        final unassigned =
            state.items.where((i) => !state.isItemAssigned(i.id)).toList();
        if (unassigned.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ada ${unassigned.length} item yang belum dibagikan. Pastikan semua item sudah dipilih.',
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      case 3:
        if (state.discountAmount > state.subtotal) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.discountExceedsSubtotal),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _saveBill() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final state = ref.read(billDraftControllerProvider);
      final completeBill = state.toCompleteBill();
      final repo = ref.read(billRepositoryProvider);

      await repo.saveBill(completeBill);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.billSavedSuccess),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(billDraftControllerProvider.notifier).resetDraft();
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan tagihan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billDraftControllerProvider);
    final controller = ref.read(billDraftControllerProvider.notifier);

    return PopScope(
      canPop: state.currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && state.currentStep > 0) {
          controller.previousStep();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            state.title.isEmpty ? AppStrings.newBillTitle : state.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (state.currentStep > 0) {
                controller.previousStep();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                context.go(AppRoutes.home);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Modern Clean Stepper Progress Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: const Border(
                  bottom: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Indicator Dots / Bars
                  Row(
                    children: List.generate(_steps.length, (index) {
                      final isDone = index < state.currentStep;
                      final isCurrent = index == state.currentStep;

                      return Expanded(
                        child: GestureDetector(
                          onTap: isDone ? () => controller.setStep(index) : null,
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(
                              right: index < _steps.length - 1 ? 6 : 0,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppColors.primary
                                  : (isDone
                                      ? AppColors.primary.withValues(alpha: 0.6)
                                      : AppColors.borderLight),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  // Step Title & Progress Counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${state.currentStep + 1}/5',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _steps[state.currentStep],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (state.currentStep < 4)
                        Text(
                          'Berikutnya: ${_steps[state.currentStep + 1]}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Step Content with isolated KeyedSubtree to guarantee clean lifecycle
            Expanded(
              child: KeyedSubtree(
                key: ValueKey('editor_step_${state.currentStep}'),
                child: switch (state.currentStep) {
                  0 => const Step1Items(),
                  1 => const Step2Participants(),
                  2 => const Step3Assign(),
                  3 => const Step4ExtraCosts(),
                  4 => const Step5Result(),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          ],
        ),

        // Persistent bottom navigation bar across ALL 5 STEPS (Never disappears)
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: const Border(
                top: BorderSide(color: AppColors.borderLight, width: 1),
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
                // Tombol Kembali: Persisten di SEMUA langkah
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (state.currentStep > 0) {
                        controller.previousStep();
                      } else {
                        context.go(AppRoutes.home);
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppStrings.back,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Tombol Lanjut / Hitung / Simpan: Aksi Kontekstual Persisten
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            if (state.currentStep == 4) {
                              _saveBill();
                            } else if (_validateStep(context, state)) {
                              controller.nextStep();
                            }
                          },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: state.currentStep == 4 ? AppColors.primary : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    state.currentStep == 0
                                        ? 'Lanjut: Peserta'
                                        : state.currentStep == 1
                                            ? 'Lanjut: Bagi Porsi'
                                            : state.currentStep == 2
                                                ? 'Lanjut: Biaya & Pajak'
                                                : state.currentStep == 3
                                                    ? 'Hitung Hasil'
                                                    : 'Simpan Tagihan',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                state.currentStep == 4
                                    ? Icons.check_circle_outline
                                    : (state.currentStep == 3
                                        ? Icons.bolt_rounded
                                        : Icons.arrow_forward_rounded),
                                size: 18,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

