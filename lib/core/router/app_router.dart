import 'package:go_router/go_router.dart';
import '../../presentation/features/bill_editor/bill_editor_screen.dart';
import '../../presentation/features/history/history_screen.dart';
import '../../presentation/features/scan/scan_screen.dart';

class AppRoutes {
  static const home = '/';
  static const billEditor = '/editor';
  static const scan = '/scan';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.billEditor,
      builder: (context, state) => const BillEditorScreen(),
    ),
    GoRoute(
      path: AppRoutes.scan,
      builder: (context, state) => const ScanScreen(),
    ),
  ],
);
