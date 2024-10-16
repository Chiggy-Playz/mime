import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';
import 'package:mime_flutter/models/settings.dart';
import 'package:mime_flutter/pages/settings/widgets/settings_group_widget.dart';
import 'package:mime_flutter/providers/settings/provider.dart';

class ThemeSettingsGroup extends ConsumerStatefulWidget {
  const ThemeSettingsGroup({super.key, required this.settings});

  final SettingsModel settings;

  @override
  ConsumerState<ThemeSettingsGroup> createState() => _ThemeSettingsGroupState();
}

class _ThemeSettingsGroupState extends ConsumerState<ThemeSettingsGroup> {
  SettingsModel get settings => widget.settings;

  Icon getThemeIcon() {
    var currentTheme = widget.settings.themeMode;
    Icon themeIcon;

    switch (currentTheme) {
      case ThemeMode.light:
        themeIcon = const Icon(Icons.light_mode_rounded);
        break;
      case ThemeMode.dark:
        themeIcon = const Icon(Icons.dark_mode_rounded);
        break;
      case ThemeMode.system:
        if (MediaQuery.of(context).platformBrightness == Brightness.light) {
          themeIcon = const Icon(Icons.light_mode_rounded);
        } else {
          themeIcon = const Icon(Icons.dark_mode_rounded);
        }
        break;
    }
    return themeIcon;
  }

  @override
  Widget build(BuildContext context) {
    return SettingsGroupWidget(
      title: 'Theme',
      children: [
        ListTile(
          title: const Text("Theme Mode"),
          subtitle: Text(settings.themeMode.name.toCapitalized()),
          leading: getThemeIcon(),
          onTap: showChangeThemeDialog,
        ),
      ],
    );
  }

  Future<void> showChangeThemeDialog() async {
    ThemeMode? result = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => AlertDialog(
        icon: getThemeIcon(),
        title: const Text("Change theme"),
        content: SizedBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              ThemeMode.values.length,
              (index) {
                return RadioListTile(
                  value: ThemeMode.values[index],
                  groupValue: settings.themeMode,
                  title: Text(ThemeMode.values[index].name.toCapitalized()),
                  onChanged: (value) => Navigator.of(context).pop(value),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );

    if (result == null) return;

    await ref.read(settingsNotifierProvider.notifier).setThemeMode(result);
  }
}
