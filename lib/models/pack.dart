import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:mime_flutter/config/constants.dart';
import 'package:mime_flutter/models/asset.dart';

part 'pack.mapper.dart';

@MappableClass()
class PackModel with PackModelMappable {
  String name;
  String id;
  String version;
  String? iconId;
  List<AssetModel> assets;

  PackModel({
    required this.name,
    required this.assets,
    required this.id,
    required this.version,
    this.iconId,
  });

  static const fromJson = PackModelMapper.fromJson;
  static const fromJsonString = PackModelMapper.fromJsonString;

  int get freeSlots => 30 - assets.length;
  bool get isAnimated => assets.isNotEmpty && assets.first.animated;

  String iconPath() {
    return "${AssetModel.directory.path}/$iconId.webp";
  }

  File iconFile() {
    return File(iconPath());
  }

  Future<File> zip() async {
    final sourceDir = await tempDir.createTemp();

    final packFile = await File("${sourceDir.path}/pack.json").create();

    // Copy icon file to the source directory
    if (iconId != null) {
      iconFile().copy("${sourceDir.path}/$iconId.webp");
    }

    await packFile.writeAsString(toJsonString());

    await Future.wait(
      assets.map(
        (asset) async {
          asset.file().copy("${sourceDir.path}/${asset.id}.webp");
        },
      ),
    );

    final zipFile = File("${tempDir.path}/$name.zip");

    await ZipFile.createFromDirectory(sourceDir: sourceDir, zipFile: zipFile);

    return zipFile;
  }
}
