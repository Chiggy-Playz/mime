import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/models/pack.dart';

class StickerPackPreview extends ConsumerStatefulWidget {
  const StickerPackPreview({super.key, required this.pack});

  final PackModel pack;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _StickerPackPreviewState();
}

class _StickerPackPreviewState extends ConsumerState<StickerPackPreview> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
