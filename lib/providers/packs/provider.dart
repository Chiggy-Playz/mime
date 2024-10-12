import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:fast_image_resizer/fast_image_resizer.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:mime_flutter/config/constants.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';
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

// This function will run in the isolate
@pragma('vm:entry-point')
Future<void> _processAssetInIsolate(Map<String, dynamic> params) async {
  final SendPort sendPort = params['sendPort'] as SendPort;
  final assetId = params['assetId'] as String;
  final bytes = params['bytes'] as List<int>?;
  final assetsDir = params['assetsDir'] as String;
  final tempDir = params['tempDir'] as String;

  // Initialize FFmpegKit in the isolate
  await FFmpegKitConfig.init();

  final tempPath = "$tempDir/$assetId";
  final outputPath = "$assetsDir/$assetId.webp";

  // If the asset is already formatted, skip the processing
  if (await File(outputPath).exists()) {
    sendPort.send(true);
    return;
  }

  // Write the bytes to temp file
  final tempFile = File(tempPath);
  await tempFile.writeAsBytes(bytes!);

  // Run ffmpeg to format the asset
  await FFmpegKit.execute(
    '-i $tempPath -y -vf "scale=512:512:force_original_aspect_ratio=decrease,pad=512:512:-1:-1:color=#00000000" -vcodec webp -pix_fmt yuva420p $outputPath',
  );

  // Delete the temp file
  await tempFile.delete();

  // Inform the main isolate that the task is complete
  sendPort.send(true);
}

// This function prepares the data and spawns an isolate for each asset
Future<void> processAssetsInParallel(
  List<AssetModel> assets,
  Directory assetsDir,
  Directory tempDir,
) async {
  final List<FlutterIsolate> isolates = [];
  final ReceivePort receivePort = ReceivePort();

  for (final asset in assets) {
    final params = {
      'sendPort': receivePort.sendPort,
      'assetId': asset.id,
      'bytes': asset.bytes,
      'assetsDir': assetsDir.path,
      'tempDir': tempDir.path,
    };

    // Spawn an isolate for each asset processing task
    final isolate = await FlutterIsolate.spawn(_processAssetInIsolate, params);
    isolates.add(isolate);
  }

  // Wait for all isolates to complete (matching the number of assets)
  int completedIsolates = 0;
  await for (final _ in receivePort) {
    completedIsolates++;
    if (completedIsolates >= assets.length) {
      break;
    }
  }

  // Kill all isolates after they have completed
  for (var isolate in isolates) {
    isolate.kill();
  }

  // Close the ReceivePort
  receivePort.close();
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

    // Check if the assets folder exists, if not create it
    final assetsDir = Directory("${docsDir.path}/assets");
    if (!await assetsDir.exists()) {
      await assetsDir.create();
    }

    await processAssetsInParallel(assets, assetsDir, tempDir);

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

  Future<void> removeAssets(
      String packIdentifier, List<AssetModel> assetsToRemove) async {
    if (assetsToRemove.isEmpty) return;

    state = AsyncData(
      state.value!.map(
        (pack) {
          if (pack.id != packIdentifier) return pack;

          return PackModel(
            name: pack.name,
            id: pack.id,
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
}
