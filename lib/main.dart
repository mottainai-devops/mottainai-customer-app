import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/invoice_detail_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pickups_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/request_pickup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/support_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationService.initialize();
  } catch (_) {
    // Firebase not yet configured — app works without push notifications
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MottainaiCustomerApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/pickups', builder: (_, __) => const PickupsScreen()),
    GoRoute(path: '/request-pickup', builder: (_, __) => const RequestPickupScreen()),
    GoRoute(path: '/invoices', builder: (_, __) => const InvoicesScreen()),
    GoRoute(
      path: '/invoices/:id',
      builder: (_, state) => InvoiceDetailScreen(invoiceId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/support', builder: (_, __) => const SupportScreen()),
  ],
);

class MottainaiCustomerApp extends StatelessWidget {
  const MottainaiCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mottainai',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          primary: const Color(0xFF1B5E20),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      routerConfig: _router,
    );
  }
}


