import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime_flutter/config/detectors.dart';
import 'package:mime_flutter/models/asset.dart';

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

// This function will run in the isolate
@pragma('vm:entry-point')
Future<void> _processAssetInIsolate(Map<String, dynamic> params) async {
  final SendPort sendPort = params['sendPort'] as SendPort;
  final assetId = params['assetId'] as String;
  final bytes = params['bytes'] as List<int>;
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
  await tempFile.writeAsBytes(bytes);

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
