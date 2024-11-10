import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/config/constants.dart';
import 'package:mime_flutter/models/asset.dart';
import 'package:mime_flutter/models/pack.dart';
import 'package:mime_flutter/models/settings.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';
import 'package:mime_flutter/pages/settings/widgets/settings_group_widget.dart';
import 'package:mime_flutter/providers/packs/provider.dart';
import 'package:mime_flutter/providers/settings/provider.dart';
import 'package:mime_flutter/widgets/confirmation_dialog.dart';
import 'package:share_plus/share_plus.dart';

class BackupSettingsGroup extends ConsumerStatefulWidget {
  const BackupSettingsGroup({super.key, required this.settings});

  final SettingsModel settings;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BackupSettingsGroupState();
}

class _BackupSettingsGroupState extends ConsumerState<BackupSettingsGroup> {
  @override
  Widget build(BuildContext context) {
    return SettingsGroupWidget(title: "Backups", children: [
      ListTile(
        title: const Text("Create backup"),
        subtitle: const Text("Create a backup of your data"),
        leading: const Icon(Icons.backup_rounded),
        onTap: () async {
          final sourceFolder = await tempDir.createTemp();
          // Store packs.json, settings.json and assets folder to the sourceFolder
          final packsString = jsonEncode(
            ref
                .read(packsNotifierProvider)
                .requireValue
                .map((pack) => pack.toJson())
                .toList(),
          );
          final settingsString = jsonEncode(
            ref.read(settingsNotifierProvider).requireValue.toJson(),
          );

          final packsFile = File("${sourceFolder.path}/packs.json");
          final settingsFile = File("${sourceFolder.path}/settings.json");

          await packsFile.writeAsString(packsString);
          await settingsFile.writeAsString(settingsString);

          // Copy assets folder
          final assetsFolder = Directory("${sourceFolder.path}/assets");
          await assetsFolder.create();

          await Future.wait(AssetModel.directory.listSync().map((assetFile) {
            final file = File(assetFile.path);
            return file
                .copy("${assetsFolder.path}/${file.path.split('/').last}");
          }));

          // Create a zip file
          final dateTime = DateTime.now().toIso8601String();
          final zipFile = File("${tempDir.path}/backup-$dateTime.zip");

          await ZipFile.createFromDirectory(
            sourceDir: sourceFolder,
            zipFile: zipFile,
          );

          // Delete the source folder
          await sourceFolder.delete(recursive: true);

          // Share the zip file
          await Share.shareXFiles([XFile(zipFile.path)]);
        },
      ),
      ListTile(
        title: const Text("Restore backup"),
        subtitle: const Text("Restore a backup of your data"),
        leading: const Icon(Icons.restore_rounded),
        onTap: () async {
          // Show dialog warning the user that the current data will be overwritten
          final confirmed = await showConfirmationDialog(
            title: "Restore backup",
            message:
                "This will overwrite your current data. Are you sure you want to continue?",
            context: context,
            dangerous: true,
          );

          if (!confirmed) return;

          // Choose the zip file from file picker
          FilePickerResult? file = await FilePicker.platform.pickFiles(
            allowMultiple: false,
            allowedExtensions: ['zip'],
            type: FileType.custom,
            dialogTitle: "Select a sticker pack zip file",
          );

          if (file == null) return;

          final path = file.files.single.path!;

          final zipFile = File(path);
          final destinationDir = await tempDir.createTemp();

          await ZipFile.extractToDirectory(
              zipFile: zipFile, destinationDir: destinationDir);

          // Validate that the destination directory contains packs.json, settings.json and assets folder
          try {
            final packsFile = File("${destinationDir.path}/packs.json");
            final settingsFile = File("${destinationDir.path}/settings.json");
            final assetsFolder = Directory("${destinationDir.path}/assets");

            if (!await packsFile.exists() ||
                !await settingsFile.exists() ||
                !await assetsFolder.exists()) {
              throw Exception("Invalid backup file");
            }

            final packsJson = await packsFile.readAsString();
            final settingsJson = await settingsFile.readAsString();

            final packs = (jsonDecode(packsJson) as List<dynamic>)
                .map((packRaw) => PackModel.fromJson(packRaw))
                .toList();
            final settings = SettingsModel.fromJson(
                jsonDecode(settingsJson) as Map<String, dynamic>);

            // Restore assets
            await Future.wait(assetsFolder.listSync().map((assetFile) {
              final file = File(assetFile.path);
              return file.copy(
                  "${AssetModel.directory.path}/${file.path.split('/').last}");
            }));

            // Restore packs
            await ref.read(packsNotifierProvider.notifier).restorePacks(packs);

            // Restore settings
            await ref
                .read(settingsNotifierProvider.notifier)
                .restoreSettings(settings);

            if (!context.mounted) return;
            context.showSnackBar("Backup restored successfully");
          } catch (e) {
            await destinationDir.delete(recursive: true);
            if (!context.mounted) return;
            context.showErrorSnackBar("Invalid backup file");
          }
        },
      ),
    ]);
  }
}
