import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/config/router.dart';

class MimeApp extends ConsumerWidget {
  const MimeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      routerConfig: router,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
    );
  }
}
