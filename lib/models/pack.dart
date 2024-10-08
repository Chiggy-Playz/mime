import 'package:dart_mappable/dart_mappable.dart';
import 'package:mime_flutter/models/asset.dart';

part 'pack.mapper.dart';

@MappableClass()
class PackModel with PackModelMappable {
  String name;
  List<AssetModel> assets;

  PackModel({
    required this.name,
    required this.assets,
  });

  static const fromJson = PackModelMapper.fromJson;
}
