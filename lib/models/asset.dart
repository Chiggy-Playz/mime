import 'dart:io';
import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';

part 'asset.mapper.dart';

@MappableClass()
class AssetModel with AssetModelMappable {
  static Directory? directory;

  final String id;
  final String name;
  final List<String> tags;
  final bool animated;
  Uint8List? bytes;

  AssetModel({
    required this.id,
    required this.name,
    required this.tags,
    required this.animated,
    this.bytes,
  });

  static const fromJson = AssetModelMapper.fromJson;

  String path() {
    return "${directory!.path}/$id.webp";
  }

  File file() {
    return File(path());
  }
}
