import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mime_flutter/config/constants.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';
import 'package:mime_flutter/models/pack.dart';
import 'package:mime_flutter/providers/packs/provider.dart';
import 'package:mime_flutter/widgets/dialog_with_textfield.dart';

const destinations = [
  NavigationDestination(icon: Icon(Icons.home), label: "Home"),
  NavigationDestination(icon: Icon(Icons.settings), label: "Settings"),
];

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  Future<void> createPressed() async {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(destinations[navigationShell.currentIndex].label),
        actions: [
          if (navigationShell.currentIndex == 0)
            IconButton(
              onPressed: () async => await importPackPressed(context, ref),
              icon: const Icon(Icons.download),
            ),
        ],
      ),
      body: navigationShell,
      floatingActionButton: navigationShell.currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final name = await showDialog<String>(
                  context: context,
                  builder: (context) => DialogWithTextfield(
                    title: "Create Pack",
                    labelText: "Name",
                    hintText: "Enter a name",
                    validator: (value) {
                      // Alpha numeric only, spaces allowed, 3-128 characters
                      final valid = RegExp(r"^[a-zA-Z0-9 ]{3,128}$")
                          .hasMatch(value ?? "");
                      return valid ? null : "Invalid name";
                    },
                    positiveButtonText: "Create",
                  ),
                );
                if (name == null) return;

                await ref.read(packsNotifierProvider.notifier).createPack(name);
              },
              tooltip: "Create",
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        destinations: destinations,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }

  Future<void> importPackPressed(BuildContext context, WidgetRef ref) async {
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

    // Validate that the destination directory contains a pack.json file and only webp files
    try {
      final packFile = File("${destinationDir.path}/pack.json");
      if (!await packFile.exists()) {
        throw Exception("Invalid pack file");
      }

      final packJson = await packFile.readAsString();
      final pack = PackModel.fromJsonString(packJson);

      final webpFiles = await destinationDir.list().toList();
      if (webpFiles.any((file) =>
          !file.path.endsWith(".webp") && !file.path.endsWith("pack.json"))) {
        throw Exception("Invalid pack file");
      }

      await ref
          .read(packsNotifierProvider.notifier)
          .importPack(pack, destinationDir);
    } on Exception catch (error) {
      if (error.toString() != "Invalid pack file") {
        rethrow;
      }
      if (!context.mounted) return;
      context.showSnackBar("Invalid pack file");
      return;
    }

    if (!context.mounted) return;
    context.showSnackBar("Pack imported successfully");
  }
}
