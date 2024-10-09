import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';
import 'package:mime_flutter/models/asset.dart';
import 'package:mime_flutter/models/pack.dart';
import 'package:mime_flutter/providers/pack_details/provider.dart';
import 'package:mime_flutter/providers/packs/errors.dart';
import 'package:mime_flutter/providers/packs/provider.dart';
import 'package:path_provider/path_provider.dart';

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
    pack = ref
        .watch(packsNotifierProvider)
        .value!
        .firstWhere((pack) => pack.id == widget.id);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.delete),
          ),
          IconButton(
            onPressed: syncToWhatsapp,
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Text(
              pack.name,
              style: context.textTheme.displaySmall,
            ),
            const Gap(8),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              children: List.generate(pack.assets.length, (index) {
                final asset = pack.assets[index];
                bool selected = state.selectedAssetIds.contains(asset.id);
                var image = Image.file(asset.file());

                var imagePaddingValue = selected ? 14.0 : 0.0;
                return GestureDetector(
                  onLongPress: () {
                    // if already selected, do nothing
                    if (selected) return;
                    if (!state.isSelecting) {
                      ref
                          .read(packDetailsNotifierProvider.notifier)
                          .toggleSelecting();
                    }
                    ref
                        .read(packDetailsNotifierProvider.notifier)
                        .toggleAssetSelection(asset.id);
                  },
                  onTap: () {
                    // if not in select mode, do nothing
                    if (!state.isSelecting) return;
                    // if already selected, deselect
                    ref
                        .read(packDetailsNotifierProvider.notifier)
                        .toggleAssetSelection(asset.id);
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      if (state.isSelecting && selected)
                        Container(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withAlpha(100),
                        ),
                      AnimatedPadding(
                        padding: EdgeInsets.all(imagePaddingValue),
                        duration: const Duration(milliseconds: 150),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(selected ? 12 : 0),
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
                              selected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: selected
                                  ? context.colorScheme.primary
                                  : Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
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
                leading: const Icon(Icons.file_copy),
                title: const Text("Import from whatsapp"),
                onTap: () {
                  Navigator.of(context).pop("whatsapp");
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
                leading: const Icon(Icons.disc_full),
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
        context.showSnackBar("Importing from gallery");
        assets = await importFromGallery();
        break;
      case "whatsapp":
        context.showSnackBar("Importing from whatsapp");
        await importFromWhatsapp();
        break;
      case "files":
        context.showSnackBar("Importing from files");
        assets = await importFromFiles();
        break;
      case "discord":
        context.showSnackBar("Importing from discord");
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
      ref.read(packsNotifierProvider.notifier).addAssets(
            pack.id,
            assets,
          );
    } on MixingAnimatedAssetsError catch (err) {
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
    return [];
    // FilePickerResult? result = await FilePicker.platform.pickFiles(
    //   allowMultiple: true,
    //   type: FileType.image,
    //   withData: true,
    // );

    // if (!mounted) return null;
    // if (result == null) {
    //   context.showSnackBar("No files selected");
    //   return null;
    // }

    // return result.files.map((file) => file.bytes!).toList();
  }

  Future<void> importFromWhatsapp() async {}

  Future<AssetModel> convertXfileToAsset(XFile image) async {
    final bytes = await image.readAsBytes();
    final hash = md5.convert(bytes).toString();
    return AssetModel(
      id: hash,
      name: image.name,
      tags: [],
      animated: false,
      bytes: bytes,
    );
  }

  Future<void> syncToWhatsapp() async {
    ref.read(packsNotifierProvider.notifier).syncPack(pack.id);
  }
}
