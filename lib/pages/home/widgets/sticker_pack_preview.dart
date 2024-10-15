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
  PackModel get pack => widget.pack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        // We'll show 3 preview stickers and 4th widget will indicate how many stickers are in the pack
        children: [
          for (var asset in pack.assets.take(3))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(asset.file()),
                  ),
                ),
                width: 64,
                height: 64,
              ),
            ),
          if (pack.assets.length > 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Center(
                  child: Text(
                    "+${pack.assets.length - 3} \nMore",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
