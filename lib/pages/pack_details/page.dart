import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import 'package:mime_flutter/config/constants.dart';
import 'package:mime_flutter/config/detectors.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';
import 'package:mime_flutter/config/mime_icons.dart';
import 'package:mime_flutter/models/asset.dart';
import 'package:mime_flutter/models/pack.dart';
import 'package:mime_flutter/providers/pack_details/provider.dart';
import 'package:mime_flutter/providers/packs/errors.dart';
import 'package:mime_flutter/providers/packs/provider.dart';
import 'package:mime_flutter/widgets/confirmation_dialog.dart';
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
        onPressed: () {},
        icon: const Icon(Icons.edit),
      ),
      IconButton(
        onPressed: syncToWhatsapp,
        icon: const Icon(Icons.sync),
      ),
      MenuAnchor(
        menuChildren: [
          MenuItemButton(
            leadingIcon: const Icon(Icons.label),
            child: const Text("Edit tags"),
            onPressed: () {},
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
      canPop: !state.isImporting && !state.isSelecting,
      onPopInvokedWithResult: (didPop, result) {
        // If importing, do not allow pop
        if (state.isImporting) {
          context.showSnackBar("Hol' up while its importing");
        }

        // If selecting, clear selection
        if (state.isSelecting) {
          ref.read(packDetailsNotifierProvider.notifier).toggleSelecting();
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
              Text(
                pack.name,
                style: context.textTheme.displaySmall,
              ),
              const Gap(8),
              StickersGridView(pack: pack),
            ],
          ),
        ),
        floatingActionButton: state.isViewing
            ? FloatingActionButton(
                onPressed: state.isImporting ? null : importPressed,
                tooltip: "Import",
                child: const Icon(Icons.download),
              )
            : null,
        bottomSheet:
            state.isSelecting ? const SelectedAssetsOptionsSheet() : null,
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
        await importFromWhatsapp();
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

  Future<void> importFromWhatsapp() async {}

  Future<AssetModel> convertXfileToAsset(XFile image) async {
    final bytes = await image.readAsBytes();
    final hash = md5.convert(bytes).toString();
    bool animated = isAnimated(bytes);

    return AssetModel(
      id: hash,
      name: image.name,
      tags: {},
      animated: animated,
      emojis: ["🫠"],
    )..bytes = bytes;
  }

  Future<void> syncToWhatsapp() async {
    ref.read(packsNotifierProvider.notifier).syncPack(pack.id);
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
}

class StickersGridView extends ConsumerStatefulWidget {
  const StickersGridView({super.key, required this.pack});

  final PackModel pack;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _StickersGridViewState();
}

class _StickersGridViewState extends ConsumerState<StickersGridView> {
  PackModel get pack => widget.pack;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(packDetailsNotifierProvider);

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      children: List.generate(pack.assets.length, (index) {
        final asset = pack.assets[index];
        bool selected = state.selectedAssetIds.contains(index);
        var image = Image.file(asset.file());

        var imagePaddingValue = selected ? 14.0 : 0.0;
        return GestureDetector(
          onLongPress: () {
            // if already selected, do nothing
            if (selected) return;
            if (!state.isSelecting) {
              if (canVibrate) Vibration.vibrate(duration: 10);
              ref.read(packDetailsNotifierProvider.notifier).toggleSelecting();
            }
            ref
                .read(packDetailsNotifierProvider.notifier)
                .toggleAssetSelection(index);
          },
          onTap: () {
            // if not in select mode, do nothing
            if (!state.isSelecting) return;
            // if already selected, deselect
            ref
                .read(packDetailsNotifierProvider.notifier)
                .toggleAssetSelection(index);
          },
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              if (state.isSelecting && selected)
                Container(
                  color: context.colorScheme.primaryContainer.withAlpha(100),
                ),
              AnimatedPadding(
                padding: EdgeInsets.all(imagePaddingValue),
                duration: const Duration(milliseconds: 150),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(selected ? 12 : 0),
                  child: image,
                ),
              ),
              if (state.isSelecting)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      color:
                          selected ? context.colorScheme.primary : Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class SelectedAssetsOptionsSheet extends ConsumerStatefulWidget {
  const SelectedAssetsOptionsSheet({super.key});

  @override
  ConsumerState<SelectedAssetsOptionsSheet> createState() =>
      _SelectedAssetsOptionsSheetState();
}

class _SelectedAssetsOptionsSheetState
    extends ConsumerState<SelectedAssetsOptionsSheet> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(packDetailsNotifierProvider);

    return TweenAnimationBuilder(
      tween: Tween<double>(
        begin: 0.0,
        end: state.selectedAssetIds.isNotEmpty ? 0.16 : 0.0,
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return DraggableScrollableSheet(
          expand: false,
          minChildSize: 0.0,
          initialChildSize: value,
          builder: (context, controller) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Material(
                    color: Colors.transparent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        if (state.selectedAssetIds.length == 1)
                          LabeledIcon(
                            iconData: Icons.edit,
                            label: "Edit \nName",
                            onTap: () async {},
                          ),
                        LabeledIcon(
                          iconData: Icons.label,
                          label: "Edit \nTags",
                          onTap: () async {},
                        ),
                        LabeledIcon(
                          iconData: Icons.delete,
                          label: "Remove",
                          onTap: () async {},
                        ),
                        LabeledIcon(
                          iconData: Icons.share,
                          label: "Share",
                          onTap: () async {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class LabeledIcon extends StatelessWidget {
  const LabeledIcon(
      {super.key,
      required this.iconData,
      required this.label,
      required this.onTap});

  final IconData iconData;
  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(64),
        radius: 128,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
          child: Column(
            children: [
              Icon(iconData, size: 24),
              const Gap(8),
              Text(
                label,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
