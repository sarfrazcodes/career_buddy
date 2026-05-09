import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'features/timer/timer_provider.dart';

import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Notifications
  await NotificationService.initializeNotification();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Dotenv load failed: $e");
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await GoogleSignIn.instance.initialize();

  runApp(const ProviderScope(child: CareerTrackerApp()));
}

class CareerTrackerApp extends ConsumerStatefulWidget {
  const CareerTrackerApp({super.key});

  @override
  ConsumerState<CareerTrackerApp> createState() => _CareerTrackerAppState();
}

class _CareerTrackerAppState extends ConsumerState<CareerTrackerApp> {
  @override
  void initState() {
    super.initState();

    // 2. Set up the Notification Action Listener
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationService.onActionReceivedMethod,
    );

    // 3. Show Boot Notification immediately if permitted
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (isAllowed) NotificationService.showIdleNotification();
    });

    // 4. Listen for clicks from the Notification tray
    NotificationService.actionStream.stream.listen((action) {
      final timerNotifier = ref.read(timerProvider.notifier);

      if (action.buttonKeyPressed.startsWith('START_')) {
        String category = action.buttonKeyPressed.replaceFirst('START_', '');
        timerNotifier.setCategory(category);
        timerNotifier.start();
      } else if (action.buttonKeyPressed == 'STOP_TIMER') {
        timerNotifier.stopAndSave(ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Career Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) return const DashboardScreen();
        return const LoginScreen();
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, trace) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}