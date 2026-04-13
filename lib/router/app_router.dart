import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/menu/pages/screens/menu_screen.dart';
import '../features/menu/pages/screens/spread_select_screen.dart';
import '../features/reading/pages/screens/consultation_screen.dart';
import '../features/splash/pages/screens/splash_screen.dart';
import '../models/reading_category.dart';
import '../models/spread_type.dart';
import '../purchase/widgets/paywall_screen.dart';
import '../purchase/widgets/subscription_manage_screen.dart';
import 'routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.menu,
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: Routes.spreadSelect,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : null;
          final category = extra?['category'] as ReadingCategory? ?? ReadingCategory.general;
          return SpreadSelectScreen(category: category);
        },
      ),
      GoRoute(
        path: Routes.consultation,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : null;
          final spread = extra?['spreadType'] as SpreadType? ?? SpreadType.generalReading;
          final category = extra?['category'] as ReadingCategory? ?? spread.category;
          return ConsultationScreen(spreadType: spread, category: category);
        },
      ),
      GoRoute(
        path: Routes.paywall,
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: Routes.subscriptionManage,
        builder: (context, state) => const SubscriptionManageScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
}
