import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/app.dart';

// ignore: depend_on_referenced_packages
import 'package:image_picker_android/image_picker_android.dart';
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mime_flutter/config/constants.dart';
import 'package:mime_flutter/models/asset.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configure();

  runApp(const ProviderScope(child: MimeApp()));
}

Future<void> configure() async {
  await Supabase.initialize(
    url: 'https://mhneoixgocviksgkjvfy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1obmVvaXhnb2N2aWtzZ2tqdmZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjgyNDMyNjcsImV4cCI6MjA0MzgxOTI2N30.yMQ2MRqZFtSq6rjTJOc0HgU9ARvseT21QkgIr7kmKIE',
  );
  dio = Dio();

  // To enable android photo picker for image_picker on Android 12 and lower
  final ImagePickerPlatform imagePickerImplementation =
      ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }

  // Load documents directory for the AssetModel
  docsDir = await getApplicationDocumentsDirectory();
  tempDir = await getTemporaryDirectory();
  AssetModel.directory = Directory("${docsDir.path}/assets");
  if (!await AssetModel.directory.exists()) {
    await AssetModel.directory.create();
  }

  FFmpegKitConfig.setSessionHistorySize(32);
  canVibrate = await Vibration.hasVibrator() ?? false;
}
