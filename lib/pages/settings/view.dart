import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/pages/settings/widgets/advanced_settings_group.dart';
import 'package:mime_flutter/pages/settings/widgets/theme_settings_group.dart';
import 'package:mime_flutter/providers/settings/provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  static const String routePath = '/settings';
  static const String routeName = 'Settings';

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  @override
  Widget build(BuildContext context) {
    var settings = ref.watch(settingsNotifierProvider);
    return settings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        return const Center(
          child: Text(
              "Uh oh! Something went wrong while trying to load settings..."),
        );
      },
      data: (settings) {
        return ListView(
          children: [
            ThemeSettingsGroup(settings: settings),
            AdvancedSettingsGroup(settings: settings),
          ],
        );
      },
    );
  }
}
