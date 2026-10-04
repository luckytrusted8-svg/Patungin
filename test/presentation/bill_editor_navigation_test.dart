import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patungin/core/constants/strings.dart';
import 'package:patungin/core/theme/app_theme.dart';
import 'package:patungin/presentation/features/bill_editor/bill_editor_screen.dart';
import 'package:patungin/presentation/providers/bill_draft_controller.dart';

void main() {
  testWidgets('BillEditorScreen renders persistent navigation bar on all steps',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial state: Step 0
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BillEditorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Step 0 bottom bar exists
    expect(find.text(AppStrings.back), findsOneWidget);
    expect(find.text('Lanjut: Peserta'), findsOneWidget);

    // Add item to enable transition to step 1
    container.read(billDraftControllerProvider.notifier).addItem(
          name: 'Nasi Goreng',
          unitPrice: 25000,
          quantity: 2,
        );
    container.read(billDraftControllerProvider.notifier).setStep(1);
    await tester.pumpAndSettle();

    // Verify Step 1 bottom bar
    expect(find.text(AppStrings.back), findsOneWidget);
    expect(find.text('Lanjut: Bagi Porsi'), findsOneWidget);

    // Add participants
    container
        .read(billDraftControllerProvider.notifier)
        .addParticipant('Andi');
    container
        .read(billDraftControllerProvider.notifier)
        .addParticipant('Budi');
    await tester.pumpAndSettle();

    // Test reordering participant up/down
    container.read(billDraftControllerProvider.notifier).moveParticipantDown(0);
    expect(container.read(billDraftControllerProvider).participants[0].name,
        'Budi');
    container.read(billDraftControllerProvider.notifier).moveParticipantUp(1);
    expect(container.read(billDraftControllerProvider).participants[0].name,
        'Andi');

    // Move to step 2 (Assign)
    container.read(billDraftControllerProvider.notifier).setStep(2);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.back), findsOneWidget);
    expect(find.text('Lanjut: Biaya & Pajak'), findsOneWidget);

    // Move to step 3 (Extra costs)
    container.read(billDraftControllerProvider.notifier).setStep(3);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.back), findsOneWidget);
    expect(find.text('Hitung Hasil'), findsOneWidget);

    // Move to step 4 (Result)
    container.read(billDraftControllerProvider.notifier).setStep(4);
    await tester.pumpAndSettle();

    // In step 4, bottom bar STILL PERSISTS with Kembali & Simpan Tagihan!
    expect(find.text(AppStrings.back), findsOneWidget);
    expect(find.text('Simpan Tagihan'), findsOneWidget);

    // Navigate back to step 3
    container.read(billDraftControllerProvider.notifier).previousStep();
    await tester.pumpAndSettle();
    expect(container.read(billDraftControllerProvider).currentStep, 3);
    expect(find.text('Hitung Hasil'), findsOneWidget);
  });
}
