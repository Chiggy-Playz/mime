import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/models/settings.dart';
import 'package:mime_flutter/pages/settings/widgets/settings_group_widget.dart';
import 'package:mime_flutter/providers/settings/provider.dart';

class AdvancedSettingsGroup extends ConsumerStatefulWidget {
  const AdvancedSettingsGroup({super.key, required this.settings});

  final SettingsModel settings;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AdvancedSettingsGroupState();
}

class _AdvancedSettingsGroupState extends ConsumerState<AdvancedSettingsGroup> {
  SettingsModel get settings => widget.settings;

  @override
  Widget build(BuildContext context) {
    return SettingsGroupWidget(
      title: 'Advanced',
      children: [
        SwitchListTile(
          value: settings.storeStickersExternally,
          title: const Text("External Sticker Directory"),
          subtitle: Text(SettingsModel.externalStickersDirectory.path),
          secondary: const Icon(Icons.folder_rounded),
          onChanged: (value) {
            ref.read(settingsNotifierProvider.notifier).setStoreStickersExternally(value);
          },
        ),
      ],
    );
  }

  // Future<void> setExternalStickersPath() async {
  //   // Choose directory
  //   final result = await FilePicker.platform.getDirectoryPath(
  //     dialogTitle: "Select a directory to store your stickers",
  //   );

  //   if (!mounted) return;

  //   if (result == null) {
  //     context.showErrorSnackBar("No directory selected");
  //     return;
  //   }

  //   Directory externalDir = Directory(result);

  //   if (await externalDir.list().length > 0) {
  //     if (!mounted) return;
  //     context.showErrorSnackBar("Directory is not empty");
  //     return;
  //   }

  //   ref.read(settingsNotifierProvider.notifier).setExternalStickersPath(result);
  // }
}
