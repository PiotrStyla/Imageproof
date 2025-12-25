import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/image_proof_viewmodel.dart';
import '../services/service_initializer.dart';
import '../../views/home_view.dart';
import '../../views/generate_proof_view.dart';
import '../../views/verify_proof_view.dart';
import '../../views/performance_dashboard_view.dart';

/// Application router with declarative navigation
class AppRouter {
  late final GoRouter router;

  AppRouter() {
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => getIt<ImageProofViewModel>(),
            child: const HomeView(),
          ),
        ),
        GoRoute(
          path: '/generate',
          name: 'generate',
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => getIt<ImageProofViewModel>(),
            child: const GenerateProofView(),
          ),
        ),
        GoRoute(
          path: '/verify',
          name: 'verify',
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => getIt<ImageProofViewModel>(),
            child: const VerifyProofView(),
          ),
        ),
        GoRoute(
          path: '/proofs',
          name: 'proofs',
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => getIt<ImageProofViewModel>(),
            child: const PerformanceDashboardView(),
          ),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Error: ${state.error}'),
        ),
      ),
    );
  }
}
