import 'dart:convert';
import 'dart:io';

import 'package:fast_image_resizer/fast_image_resizer.dart';

import 'package:flutter/services.dart';

import 'package:mime_flutter/config/constants.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';
import 'package:mime_flutter/config/utils.dart';
import 'package:mime_flutter/models/asset.dart';
import 'package:mime_flutter/models/pack.dart';
import 'package:mime_flutter/models/settings.dart';
import 'package:mime_flutter/providers/packs/errors.dart';
import 'package:mime_flutter/providers/settings/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_stickers_handler/exceptions.dart';
import 'package:whatsapp_stickers_handler/whatsapp_stickers_handler.dart';

part 'provider.g.dart';

@Riverpod()
class PacksNotifier extends _$PacksNotifier {
  SharedPreferences? prefs;
  SettingsModel? settings;
  Uuid uuid = const Uuid();

  @override
  Future<List<PackModel>> build() async {
    prefs ??= await SharedPreferences.getInstance();
    settings = ref.watch(settingsNotifierProvider).valueOrNull;

    final packsJson = prefs!.getString("packs");

    if (packsJson != null) {
      final List<dynamic> packs = jsonDecode(packsJson);
      return packs.map((e) => PackModel.fromJson(e)).toList();
    }

    return [];
  }

  Future<void> save() async {
    final packs = state.value!.map((e) => e.toJson()).toList();
    await prefs!.setString("packs", jsonEncode(packs));

    // Write the packs to the external storage
    await saveToExternalStorage();
  }

  Future<void> saveToExternalStorage() async {
    if (settings == null || settings!.externalStickersStoragePath == null) {
      return;
    }

    final extDir = settings!.externalStickersDirectory;
    final packIds = state.value!.map((e) => e.id).toSet();

    // Add the packs to the external storage
    for (final pack in state.value!) {
      // Check if pack folder is created
      final packDir = Directory("${extDir.path}/${pack.id}");
      if (!await packDir.exists()) {
        await packDir.create();
      }

      for (final asset in pack.assets) {
        // Copy the assets to the pack folder
        final source = File("${AssetModel.directory.path}/${asset.id}.webp");
        final destination = File(
            "${packDir.path}/${asset.id}-${asset.name}-${asset.tags.join('-')}-${pack.name}.webp");
        if (!await destination.exists()) {
          await destination.writeAsBytes(
            await source.readAsBytes(),
            flush: true,
          );
        }
      }

      // Remove any assets that are not in the state
      final extPackAssets = await packDir.list().toSet();
      final assetIds = pack.assets.map((e) => e.id).toList();
      for (final extPackAsset in extPackAssets) {
        final assetId = extPackAsset.path
            .split("/")
            .last
            .split("-")
            .first
            .replaceAll(".webp", "");
        if (!assetIds.contains(assetId)) {
          await extPackAsset.delete();
        }
      }
    }

    // Remove any packs that are not in the state
    final extPacks = await extDir.list().toList();
    for (final extPack in extPacks) {
      final packId = extPack.path.split("/").last;
      if (!packIds.contains(packId)) {
        await extPack.delete(recursive: true);
      }
    }
  }

  Future<void> createPack(String name) async {
    state = AsyncData(
      [
        ...state.value!,
        PackModel(
          name: name,
          id: uuid.v4(),
          version: "1",
          assets: [],
        ),
      ],
    );
    await save();
  }

  Future<void> deletePack(String identifier) async {
    state = AsyncData(
      state.value!.where((e) => e.id != identifier).toList(),
    );
    await save();
  }

  Future<void> syncPack(String id) async {
    final pack = state.value!.firstWhere((element) => element.id == id);

    // Validate the pack
    // Number of assets should be at least 3 and at most 30
    if (pack.assets.length < 3 || pack.assets.length > 30) {
      throw InvalidPackSizeError();
    }

    final dir = await getApplicationDocumentsDirectory();

    final Uint8List bytes;
    // Prepare tray icon
    if (pack.iconId == null) {
      final trayIconImage = await rootBundle.load('assets/icons/icon.png');
      bytes = trayIconImage.buffer.asUint8List();
    } else {
      final trayIconImage = pack.iconFile();
      bytes = await trayIconImage.readAsBytes();
    }

    final trayIconBytes = await resizeImage(
      bytes,
      width: 96,
      height: 96,
    );

    final trayIcon = File('${dir.path}/assets/icon.png');
    await trayIcon.writeAsBytes(trayIconBytes!.buffer.asInt8List(),
        flush: true);

    final WhatsappStickersHandler whatsappStickersHandler =
        WhatsappStickersHandler();
    try {
      await whatsappStickersHandler.addStickerPack(
        pack.id,
        pack.name,
        "Mime",
        "file://${trayIcon.path}",
        "",
        "",
        "",
        pack.isAnimated,
        Map.fromEntries(
          pack.assets.map(
            (asset) => MapEntry(
              "file://${asset.path()}",
              ["🫠"],
            ),
          ),
        ),
      );
    } on WhatsappStickersException catch (e) {
      if (e.cause == "already_added") return;
      rethrow;
    }
  }

  Future<void> addAssets(String packIdentifier, List<AssetModel> assets) async {
    final pack =
        state.value!.firstWhere((element) => element.id == packIdentifier);

    // Validation
    if (assets.isEmpty) return;

    final isAnimated = assets.first.animated;
    if ((assets + pack.assets).any((asset) => asset.animated != isAnimated)) {
      throw MixingAnimatedAssetsError();
    }

    // Remove any duplicate assets from itself and the pack
    assets.removeWhere((asset) => pack.assets.contains(asset));

    if (assets.isEmpty) return;

    await processAssetsInParallel(assets, AssetModel.directory, tempDir);

    state = AsyncData(
      state.value!.map(
        (pack) {
          if (pack.id != packIdentifier) return pack;

          return pack.copyWith(
            assets: pack.assets + assets,
            version: pack.version.increment(),
          );
        },
      ).toList(),
    );

    await save();
  }

  Future<void> removeAssets(
      String packIdentifier, List<AssetModel> assetsToRemove) async {
    if (assetsToRemove.isEmpty) return;

    state = AsyncData(
      state.value!.map(
        (pack) {
          if (pack.id != packIdentifier) return pack;

          return pack.copyWith(
            assets: pack.assets
                .where((asset) => !assetsToRemove.contains(asset))
                .toList(),
            version: pack.version.increment(),
          );
        },
      ).toList(),
    );

    await save();
  }

  Future<void> setPackIcon(String packIdentifier, String? iconId) async {
    state = AsyncData(
      state.value!.map(
        (pack) {
          if (pack.id != packIdentifier) return pack;

          return pack.copyWith(
            iconId: iconId,
            version: pack.version.increment(),
          );
        },
      ).toList(),
    );

    await save();
  }

  Future<void> setPackName(String packIdentifier, String name) async {
    state = AsyncData(
      state.value!.map(
        (pack) {
          if (pack.id != packIdentifier) return pack;

          return pack.copyWith(name: name, version: pack.version.increment());
        },
      ).toList(),
    );

    await save();
  }

  Future<void> updateAssetTags(
    String packIdentifier,
    List<String> assetIds,
    Set<String> tagsToAdd,
    Set<String> tagsToRemove,
  ) async {
    state = AsyncData(
      state.value!.map(
        (pack) {
          if (pack.id != packIdentifier) return pack;

          final updatedAssets = pack.assets.map(
            (asset) {
              if (!assetIds.contains(asset.id)) return asset;

              return asset.copyWith(
                tags: asset.tags.difference(tagsToRemove).union(tagsToAdd),
              );
            },
          ).toList();

          return pack.copyWith(
            assets: updatedAssets,
            version: pack.version.increment(),
          );
        },
      ).toList(),
    );

    await save();
  }

  Future<void> updateAssetName(
    String packIdentifier,
    String assetId,
    String newName,
  ) async {
    state = AsyncData(
      state.value!.map(
        (pack) {
          if (pack.id != packIdentifier) return pack;

          final updatedAssets = pack.assets.map(
            (asset) {
              if (asset.id != assetId) return asset;

              return asset.copyWith(
                name: newName,
              );
            },
          ).toList();

          return pack.copyWith(
            assets: updatedAssets,
            version: pack.version.increment(),
          );
        },
      ).toList(),
    );

    await save();
  }

  Future<void> importPack(PackModel pack, Directory destinationDir) async {
    await Future.wait(
      pack.assets.map(
        (asset) async {
          final source = File("${destinationDir.path}/${asset.id}.webp");
          final destination =
              File("${AssetModel.directory.path}/${asset.id}.webp");

          await source.copy(destination.path);
        },
      ),
    );

    // Copy the icon to the asset directory
    if (pack.iconId != null) {
      final source = File("${destinationDir.path}/${pack.iconId}.webp");
      final destination =
          File("${AssetModel.directory.path}/${pack.iconId}.webp");

      await source.copy(destination.path);
    }

    state = AsyncData(
      [
        ...state.value!,
        pack,
      ],
    );

    await save();
  }

  Future<void> restorePacks(List<PackModel> packs) async {
    state = AsyncData(packs);
    await save();
  }
}
