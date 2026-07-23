import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/datasources/local/database_helper.dart';
import 'presentation/providers/theme_provider.dart';

/// Entry point of maochanicProFresh.
/// Initialises Flutter bindings, database, and launches the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for consistent UI on phones
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Initialise SQLite database
  await DatabaseHelper.instance.init();

  runApp(
    // ProviderScope is the root of all Riverpod providers
    const ProviderScope(
      child: MechProApp(),
    ),
  );
}

/// Root application widget.
class MechProApp extends ConsumerWidget {
  const MechProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'maochanicProFresh',
      debugShowCheckedModeBanner: false,

      // Material 3 themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // GoRouter integration
      routerConfig: router,
    );
  }
}
