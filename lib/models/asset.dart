import 'package:dart_mappable/dart_mappable.dart';

part 'asset.mapper.dart';

@MappableClass()
class AssetModel with AssetModelMappable {
  final String? id;
  final String? name;
  final List<String> tags;
  final bool animated;

  AssetModel({
    this.id,
    this.name,
    required this.tags,
    required this.animated,
  });

  static const fromJson = AssetModelMapper.fromJson;
}
