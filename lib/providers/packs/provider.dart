import 'dart:convert';
import 'dart:io';

import 'package:fast_image_resizer/fast_image_resizer.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:flutter/services.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';
import 'package:mime_flutter/models/asset.dart';
import 'package:mime_flutter/models/pack.dart';
import 'package:mime_flutter/providers/packs/errors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_stickers_handler/whatsapp_stickers_handler.dart';

part 'provider.g.dart';

/// Assumes `bytes` property is not null for given asset
Future<void> formatAndSaveAsset(
  Directory assetsDir,
  Directory tempDir,
  AssetModel asset,
) async {
  final tempPath = "${tempDir.path}/${asset.id}";
  final outputPath = "${assetsDir.path}/${asset.id}.webp";

  // Write the bytes to temp file
  final tempFile = File(tempPath);
  await tempFile.writeAsBytes(asset.bytes!);

  // Run ffmpeg to format the asset
  await FFmpegKit.execute(
    '-i $tempPath -y -vf "scale=512:512:force_original_aspect_ratio=decrease,pad=512:512:-1:-1:color=#00000000" -vcodec webp -pix_fmt yuva420p $outputPath',
  );

  // Delete the temp file
  await tempFile.delete();
}

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

  Future<void> addAssets(
    String packIdentifier,
    List<AssetModel> assets, {
    bool writeToDisk = true,
  }) async {
    // Validation
    if (assets.isEmpty) return;

    // All the assets must be either animated or not animated. No mixing allowed
    final isAnimated = assets.first.animated;
    if (assets.any((asset) => asset.animated != isAnimated)) {
      throw MixingAnimatedAssetsError();
    }

    // If write to disk, then we save the assets to app's documents directory
    if (writeToDisk) {
      final documentDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();

      // Check if the assets folder exists, if not create it
      final assetsDir = Directory("${documentDir.path}/assets");
      if (!await assetsDir.exists()) {
        await assetsDir.create();
      }

      await Future.wait(
          assets.map((asset) => formatAndSaveAsset(assetsDir, tempDir, asset)));
    }

    state = AsyncData(
      state.value!.map(
        (pack) {
          if (pack.id != packIdentifier) return pack;

          return PackModel(
            name: pack.name,
            id: pack.id,
            assets: pack.assets + assets,
            version: pack.version.increment(),
          );
        },
      ).toList(),
    );

    await save();
  }

  Future<void> syncPack(String id) async {
    final pack = state.value!.firstWhere((element) => element.id == id);

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

    await whatsappStickersHandler.addStickerPack(
      pack.id,
      pack.name,
      "Chiggy",
      "file://${trayIcon.path}",
      "",
      "",
      "",
      false,
      Map.fromEntries(
        pack.assets.map(
          (asset) => MapEntry(
            "file://${asset.path()}",
            ["🫠"],
          ),
        ),
      ),
    );
  }
}
