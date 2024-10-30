import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';
import 'package:mime_flutter/models/settings.dart';
import 'package:mime_flutter/pages/settings/widgets/settings_group_widget.dart';
import 'package:mime_flutter/providers/settings/provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
        ListTile(
          title: const Text("External Sticker Directory"),
          subtitle: Text(settings.externalStickersStoragePath ?? "Not set"),
          leading: const Icon(Icons.folder_rounded),
          trailing: settings.externalStickersStoragePath == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () {
                    ref
                        .read(settingsNotifierProvider.notifier)
                        .setExternalStickersPath(null);
                  },
                ),
          onTap: setExternalStickersPath,
        )
      ],
    );
  }

  Future<void> setExternalStickersPath() async {
    final manageExternalStoragePerm =
        await Permission.manageExternalStorage.request();

    if (!mounted) return;
    if (manageExternalStoragePerm != PermissionStatus.granted) {
      context.showErrorSnackBar(
        "Permission denied",
        action: SnackBarAction(
          label: "Info",
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Permission Info"),
                  content: const Text(
                    "This permission is required to access the external storage to store your stickers. Only the directory you choose will be used to store your stickers.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Close"),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );
      return;
    }

    // Choose directory
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Select a directory to store your stickers",
    );

    if (!mounted) return;

    if (result == null) {
      context.showErrorSnackBar("No directory selected");
      return;
    }

    Directory externalDir = Directory(result);

    if (await externalDir.list().length > 0) {
      if (!mounted) return;
      context.showErrorSnackBar("Directory is not empty");
      return;
    }

    ref.read(settingsNotifierProvider.notifier).setExternalStickersPath(result);
  }
}
