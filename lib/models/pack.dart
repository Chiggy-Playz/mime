import 'package:dart_mappable/dart_mappable.dart';
import 'package:mime_flutter/models/asset.dart';

part 'pack.mapper.dart';

@MappableClass()
class PackModel with PackModelMappable {
  String name;
  String id;
  String? assetPath;
  String version;
  List<AssetModel> assets;

  PackModel({
    required this.name,
    required this.assets,
    required this.id,
    required this.version,
    this.assetPath,
  });

  static const fromJson = PackModelMapper.fromJson;

  int get freeSlots => 30 - assets.length;
  bool get isAnimated => assets.isNotEmpty && assets.first.animated;
}
