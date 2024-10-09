import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/app.dart';

// ignore: depend_on_referenced_packages
import 'package:image_picker_android/image_picker_android.dart';
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mime_flutter/models/asset.dart';
import 'package:path_provider/path_provider.dart';

const dirPath = "Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Stickers";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // To enable android photo picker for image_picker on Android 12 and lower
  final ImagePickerPlatform imagePickerImplementation =
      ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }

  // Load documents directory for the AssetModel
  final docsDir = await getApplicationDocumentsDirectory();
  AssetModel.directory = Directory("${docsDir.path}/assets");

  FFmpegKitConfig.setSessionHistorySize(32);

  runApp(const ProviderScope(child: MimeApp()));
}
