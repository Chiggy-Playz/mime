import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';

part 'discord_asset.mapper.dart';

@MappableEnum()
enum DiscordAssetType {
  emoji,
  sticker,
  attachment,
}

@MappableClass()
class DiscordAssetModel with DiscordAssetModelMappable {
  final int id;
  final String name;
  final bool animated;
  final DiscordAssetType type;

  DiscordAssetModel({
    required this.id,
    required this.name,
    required this.animated,
    required this.type,
  });

  static const fromJson = DiscordAssetModelMapper.fromJson;

  String get extension => animated ? "gif" : "webp";

  String get fileName => '$name.$extension';

  String get url {
    switch (type) {
      case DiscordAssetType.emoji:
        return 'https://cdn.discordapp.com/emojis/$id.$extension?quality=lossless&size=512';
      case DiscordAssetType.sticker:
        return 'https://media.discordapp.net/stickers/$id.$extension?quality=lossless&size=160';
      case DiscordAssetType.attachment:
        return 'https://cdn.discordapp.com/attachments/$id';
    }
  }

  Future<void> download(File outputFile) async {
    // Download the asset to the file
    final response = await HttpClient().getUrl(Uri.parse(url));
    final request = await response.close();
    await request.pipe(outputFile.openWrite());
  }
}
