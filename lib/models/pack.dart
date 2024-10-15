import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
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

  int get freeSlots => 30 - assets.length;
  bool get isAnimated => assets.isNotEmpty && assets.first.animated;

  String iconPath() {
    return "${AssetModel.directory.path}/$iconId.webp";
  }

  File iconFile() {
    return File(iconPath());
  }
}
