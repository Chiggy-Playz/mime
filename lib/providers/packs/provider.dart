import 'dart:convert';
import 'dart:io';

import 'package:fast_image_resizer/fast_image_resizer.dart';

import 'package:flutter/services.dart';

import 'package:mime_flutter/config/constants.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';
import 'package:mime_flutter/config/utils.dart';
import 'package:mime_flutter/models/asset.dart';
import 'package:mime_flutter/models/pack.dart';
import 'package:mime_flutter/providers/packs/errors.dart';
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
  Uuid uuid = const Uuid();

  @override
  Future<List<PackModel>> build() async {
    prefs ??= await SharedPreferences.getInstance();

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

    // Prepare tray icon
    final trayIconImage = await rootBundle.load('assets/icons/icon.png');
    final trayIconBytes = await resizeImage(
      Uint8List.view(trayIconImage.buffer),
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
        "Chiggy",
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

  Future<void> setPackIcon(String packIdentifier, String iconId) async {
    state = AsyncData(
      state.value!.map(
        (pack) {
          if (pack.id != packIdentifier) return pack;

          return pack.copyWith(
              iconid: iconId, version: pack.version.increment());
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
}
