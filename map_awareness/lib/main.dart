import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:map_awareness/router/app_router.dart';
import 'package:map_awareness/providers/app_providers.dart';
import 'package:map_awareness/utils/app_theme.dart';

/// Entry point: initializes bindings, loads theme, and launches the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  
  // Loads saved theme preference.
  final savedThemeIndex = await loadSavedThemeMode();
  
  runApp(ProviderScope(
    overrides: [
      themeModeProvider.overrideWith((ref) => AppTheme.themeModeFromIndex(savedThemeIndex)),
    ],
    child: const MyApp(),
  ));
}

/// Root application widget that configures MaterialApp, router, and themes.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final themeMode = ref.watch(themeModeProvider);

    Widget app = ToastificationWrapper(
      child: MaterialApp.router(
        title: 'Map Awareness',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: AppRouter.router,
      ),
    );

    if (isWindows) {
      app = ExcludeSemantics(child: app);
    }

    return app;
  }
}
