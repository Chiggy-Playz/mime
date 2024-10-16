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
  final animated = params['animated'] as bool;

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

  int bitrate = animated ? 800 : 1600; // Start with higher bitrates
  int duration = 10;
  final int maxSize = animated ? 500 * 1024 : 100 * 1024;
  int quality = 90;
  int fps = 25; // Start with 25 fps for animated files

  int previousSize = 0;

  while (true) {
    String ffmpegCommand = animated
        ? '-i $tempPath -y '
            '-vf "fps=$fps,scale=512:512:force_original_aspect_ratio=decrease,pad=512:512:-1:-1:color=#00000000,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" '
            '-loop 0 -preset picture -an -vsync 0 -t 00:00:$duration -b:v ${bitrate}k '
            '-vcodec webp -pix_fmt yuva420p $outputPath'
        : '-i $tempPath -y -vf "scale=512:512:force_original_aspect_ratio=decrease,pad=512:512:-1:-1:color=#00000000" '
            '-vcodec webp -pix_fmt yuva420p -quality $quality $outputPath';

    await FFmpegKit.execute(ffmpegCommand);

    final int outputSize = await File(outputPath).length();

    if (outputSize <= maxSize) break;

    if (outputSize == previousSize) {
      // If size hasn't changed for 1 iterations, make a more drastic change
      bitrate = (bitrate * 0.8).round();
      quality -= 15;
      fps = (fps * 0.8).round();
    }

    previousSize = outputSize;

    if (animated) {
      if (bitrate > 100) {
        bitrate = (bitrate * 0.9).round();
      } else if (fps > 10) {
        fps--;
      } else if (duration > 5) {
        duration--;
      }
    } else {
      if (quality > 50) quality -= 10;
    }

    if (bitrate < 50 && fps <= 10 && duration <= 5) {
      break; // Stop if we've reduced parameters too much
    }
  }

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
      'animated': asset.animated,
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

