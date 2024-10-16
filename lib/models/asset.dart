import 'dart:io';
import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:image_picker/image_picker.dart';

part 'asset.mapper.dart';

@MappableClass()
class AssetModel with AssetModelMappable {
  static late Directory directory;

  final String id;
  final String name;
  final Set<String> tags;
  final bool animated;
  final List<String> emojis;

  Uint8List? bytes;

  AssetModel({
    required this.id,
    required this.name,
    required this.tags,
    required this.animated,
    required this.emojis,
  });

  static const fromJson = AssetModelMapper.fromJson;

  // Equality based on id
  @override
  bool operator ==(Object other) {
    return other is AssetModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  String path() {
    return "${directory.path}/$id.webp";
  }

  File file() {
    return File(path());
  }

  XFile xFile() {
    return XFile(path());
  }

}
