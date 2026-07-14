import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/paper_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/ad_service.dart';
import 'services/analytics_service.dart';
import 'services/profile_storage.dart';
import 'services/text_scale_storage.dart';
import 'services/theme_mode_storage.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await ThemeModeController.instance.load();
  await TextScaleController.instance.load();
  await AdService.instance.initialize();
  await Firebase.initializeApp();
  await AnalyticsService.instance.initialize();
  AnalyticsService.instance.logAppOpen();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.initialize();
  runApp(const DailyThesisApp());
}

class DailyThesisApp extends StatelessWidget {
  const DailyThesisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeModeController.instance.notifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'DailyThesis',
          theme: buildAppTheme(AppPalette.light, Brightness.light),
          darkTheme: buildAppTheme(AppPalette.dark, Brightness.dark),
          themeMode: themeMode,
          builder: (context, child) {
            final brightness = switch (themeMode) {
              ThemeMode.dark => Brightness.dark,
              ThemeMode.light => Brightness.light,
              ThemeMode.system => MediaQuery.platformBrightnessOf(context),
            };
            final palette = brightness == Brightness.dark
                ? AppPalette.dark
                : AppPalette.light;

            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    brightness == Brightness.dark ? Brightness.light : Brightness.dark,
                systemNavigationBarColor: palette.background,
                systemNavigationBarIconBrightness:
                    brightness == Brightness.dark ? Brightness.light : Brightness.dark,
              ),
            );

            return ValueListenableBuilder<AppTextScale>(
              valueListenable: TextScaleController.instance.notifier,
              builder: (context, textScale, _) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(textScale.factor),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
          home: const AppRoot(),
        );
      },
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _storage = ProfileStorage();
  bool? _hasProfile; // null = still checking

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    final has = await _storage.hasProfile();
    setState(() => _hasProfile = has);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasProfile == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const SizedBox(),
      );
    }

    if (_hasProfile == false) {
      return OnboardingScreen(
        onComplete: () => setState(() => _hasProfile = true),
      );
    }

    return const PaperScreen();
  }
}
