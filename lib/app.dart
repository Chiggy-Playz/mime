import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/config/router.dart';
import 'package:mime_flutter/providers/settings/provider.dart';

class MimeApp extends ConsumerWidget {
  const MimeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return ref.watch(settingsNotifierProvider).when(
          loading: () => Container(),
          error: (error, stackTrace) {
            return const Scaffold(
              body: Center(
                child: Text(
                    'An error occurred while loading settings. Try clearing app data?'),
              ),
            );
          },
          data: (settings) {
            return MaterialApp.router(
              routerConfig: router,
              themeMode: settings.themeMode,
              darkTheme: ThemeData.dark().copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            );
          },
        );
  }
}
