import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:mime_flutter/config/constants.dart';

import 'package:mime_flutter/config/extensions/extensions.dart';
import 'package:mime_flutter/config/mime_icons.dart';
import 'package:mime_flutter/config/utils.dart';
import 'package:mime_flutter/models/asset.dart';
import 'package:mime_flutter/models/pack.dart';
import 'package:mime_flutter/pages/asset_details/page.dart';
import 'package:mime_flutter/pages/pack_details/widgets/selected_assets_options_sheet.dart';
import 'package:mime_flutter/pages/pack_details/widgets/sticker_pack_header.dart';
import 'package:mime_flutter/widgets/stickers_grid_view.dart';
import 'package:mime_flutter/providers/pack_details/provider.dart';
import 'package:mime_flutter/providers/packs/errors.dart';
import 'package:mime_flutter/providers/packs/provider.dart';
import 'package:mime_flutter/widgets/confirmation_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';

class PackDetailsPage extends ConsumerStatefulWidget {
  const PackDetailsPage({
    super.key,
    required this.id,
  });

  final String id;

  static const routePath = "/pack/:id";
  static const routeName = "Pack Details";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => PackDetailsPageState();
}

class PackDetailsPageState extends ConsumerState<PackDetailsPage> {
  late PackModel pack;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(packDetailsNotifierProvider);

    // We are doing a firstOrNull becuase this build function refires when the
    // pack is deleted, so the id isnt found in the packs list. And it errors out.
    final packT = ref
        .watch(packsNotifierProvider)
        .value!
        .where((pack) => pack.id == widget.id)
        .firstOrNull;

    if (packT != null) {
      pack = packT;
    }

    List<Widget> actions = [
      IconButton(
        onPressed: ref.read(packDetailsNotifierProvider.notifier).toggleEditing,
        icon: Icon(state.isEditing ? Icons.check : Icons.edit),
      ),
      if (state.isViewing) ...[
        IconButton(
          onPressed: syncToWhatsapp,
          icon: const Icon(Icons.sync),
        ),
        MenuAnchor(
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Icons.share),
              child: const Text("Share"),
              onPressed: sharePackPressed,
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.delete),
              onPressed: deletePack,
              child: const Text("Delete pack"),
            ),
          ],
          builder: (context, controller, child) => IconButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon: const Icon(Icons.more_vert),
          ),
        )
      ]
    ];

    if (state.isImporting) {
      actions = [];
    }

    if (state.isSelecting) {
      actions = [
        IconButton(
          onPressed: () {
            if (state.selectedAssetIds.length == pack.assets.length) {
              ref.read(packDetailsNotifierProvider.notifier).toggleSelecting();
            } else {
              ref
                  .read(packDetailsNotifierProvider.notifier)
                  .selectAll(List.generate(pack.assets.length, (i) => i));
            }
          },
          icon: const Icon(Icons.select_all),
        ),
      ];
    }

    return PopScope(
      canPop: state.isViewing && !state.isImporting,
      onPopInvokedWithResult: (didPop, result) {
        // If importing, do not allow pop
        if (state.isImporting) {
          context.showSnackBar("Hol' up while its importing");
        }

        // If selecting, clear selection
        if (state.isSelecting) {
          ref.read(packDetailsNotifierProvider.notifier).toggleSelecting();
        }

        // If editing, cancel editing
        if (state.isEditing) {
          ref.read(packDetailsNotifierProvider.notifier).toggleEditing();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !state.isSelecting,
          title: state.isSelecting
              ? ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                  ),
                  icon: const Icon(Icons.close),
                  label: Text(state.selectedAssetIds.length.toString()),
                  onPressed: () {
                    ref
                        .read(packDetailsNotifierProvider.notifier)
                        .toggleSelecting();
                  },
                )
              : null,
          actions: actions,
        ),
        body: Center(
          child: Column(
            children: [
              if (state.isImporting) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: StickerPackHeader(pack: pack),
              ),
              const Gap(8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: StickersGridView(
                  stickerPaths:
                      pack.assets.map((asset) => asset.path()).toList(),
                  onStickerTap: (selected, index) async {
                    // if not in select mode, do nothing
                    if (!state.isSelecting) {
                      context.pushNamed(
                        AssetDetailsPage.routeName,
                        pathParameters: {
                          "packId": pack.id,
                          "assetId": pack.assets[index].id,
                        },
                      );
                      return;
                    }
                    // if already selected, deselect
                    ref
                        .read(packDetailsNotifierProvider.notifier)
                        .toggleAssetSelection(index);
                  },
                  onStickerLongPress: (selected, index) async {
                    // if already selected, do nothing
                    if (selected) return;
                    if (!state.isSelecting) {
                      if (canVibrate) Vibration.vibrate(duration: 10);
                      ref
                          .read(packDetailsNotifierProvider.notifier)
                          .toggleSelecting();
                    }
                    ref
                        .read(packDetailsNotifierProvider.notifier)
                        .toggleAssetSelection(index);
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: state.isViewing && !state.isImporting
            ? FloatingActionButton(
                onPressed: importPressed,
                tooltip: "Import",
                child: const Icon(Icons.download),
              )
            : null,
        bottomSheet:
            state.isSelecting ? SelectedAssetsOptionsSheet(pack: pack) : null,
      ),
    );
  }

  Future<void> importPressed() async {
    // Show bottom modal sheet with 3 list tile,
    // 1. Import from gallery
    // 2. Import from whatsapp
    // 3. Import from files

    // When user selects one of the options, close the modal sheet
    // and show a snackbar with the message "Importing from <option>"

    final option = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text("Import from gallery"),
                onTap: () {
                  Navigator.of(context).pop("gallery");
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text("Import from files"),
                onTap: () {
                  Navigator.of(context).pop("files");
                },
              ),
              ListTile(
                leading: const Icon(MimeIcons.whatsapp),
                title: const Text("Import from whatsapp"),
                onTap: () {
                  Navigator.of(context).pop("whatsapp");
                },
              ),
              ListTile(
                leading: const Icon(MimeIcons.discord),
                title: const Text("Import from discord"),
                onTap: () {
                  Navigator.of(context).pop("discord");
                },
              ),
            ],
          ),
        );
      },
    );

    if (option == null || !mounted) return;

    List<AssetModel>? assets;

    switch (option) {
      case "gallery":
        assets = await importFromGallery();
        break;
      case "files":
        assets = await importFromFiles();
        break;
      case "whatsapp":
        assets = await importFromWhatsapp();
        break;
      case "discord":
        break;
      default:
        throw UnimplementedError("Unknown option: $option");
    }

    if (assets == null || assets.isEmpty || !mounted) return;

    if (assets.length > pack.freeSlots) {
      context.showErrorSnackBar("Not enough free slots");
      return;
    }

    ref.read(packDetailsNotifierProvider.notifier).toggleImporting();
    try {
      await ref.read(packsNotifierProvider.notifier).addAssets(pack.id, assets);
    } on MixingAnimatedAssetsError catch (err) {
      if (!mounted) return;
      context.showErrorSnackBar(err.message);
    } finally {
      ref.read(packDetailsNotifierProvider.notifier).toggleImporting();
    }
  }

  Future<List<AssetModel>?> importFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images =
        await picker.pickMultipleMedia(limit: pack.freeSlots);

    if (!mounted) return null;
    if (images.isEmpty) {
      context.showSnackBar("No image selected");
      return null;
    }

    return await Future.wait(images.map((image) => convertXfileToAsset(image)));
  }

  Future<List<AssetModel>?> importFromFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
      allowCompression: false,
      compressionQuality: 0,
    );

    if (!mounted) return null;
    if (result == null) {
      context.showSnackBar("No files selected");
      return null;
    }

    return await Future.wait(
        result.xFiles.map((image) => convertXfileToAsset(image)));
  }

  Future<List<AssetModel>?> importFromWhatsapp() async {
    // Show a dialog box to the user
    // Informing them where they can find the stickers
    // And then tell them to sort by date descending

    // Once the user has done that, they can press the button to continue

    String message =
        "You can find WhatsApp stickers in the following path:\n\n $whatsappStickersPath\n\n"
        "Make sure to sort by date descending to find the latest stickers.";

    final confirmed = await showConfirmationDialog(
      title: "How to import from WhatsApp",
      message: message,
      context: context,
      icon: Icons.info,
      confirmText: "Got it",
    );

    if (!confirmed) return null;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
      allowCompression: false,
      compressionQuality: 0,
    );

    if (!mounted) return null;
    if (result == null) {
      context.showSnackBar("No files selected");
      return null;
    }

    return await Future.wait(
        result.xFiles.map((image) => convertXfileToAsset(image)));
  }

  Future<void> syncToWhatsapp() async {
    try {
      await ref.read(packsNotifierProvider.notifier).syncPack(pack.id);
    } on InvalidPackSizeError catch (err) {
      if (!mounted) return;
      context.showErrorSnackBar(err.message);
    }
  }

  Future<void> deletePack() async {
    // Confirm Dialog
    final confirmed = await showConfirmationDialog(
      title: "Delete ${pack.name}",
      message:
          "Are you sure you want to delete this pack? This action is irreversible and stickers will be lost.",
      context: context,
      dangerous: true,
    );

    if (!confirmed) return;
    if (!mounted) return;

    context.pop();
    await ref.read(packsNotifierProvider.notifier).deletePack(pack.id);
  }

  Future<void> sharePackPressed() async {
    final zipFile = await pack.zip();

    await Share.shareXFiles([XFile(zipFile.path)], text: pack.name);
  }
}
