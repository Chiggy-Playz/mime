import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';
import 'package:mime_flutter/providers/pack_details/provider.dart';

typedef StickerInteractCallback = Future<void> Function(
    bool selected, int index);

class StickersGridView extends ConsumerStatefulWidget {
  const StickersGridView({
    super.key,
    required this.imageProviders,
    required this.onStickerTap,
    required this.onStickerLongPress,
  });

  final List<ImageProvider> imageProviders;
  final StickerInteractCallback onStickerTap;
  final StickerInteractCallback onStickerLongPress;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _StickersGridViewState();
}

class _StickersGridViewState extends ConsumerState<StickersGridView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(packDetailsNotifierProvider);

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      children: List.generate(widget.imageProviders.length, (index) {
        final imageProvider = widget.imageProviders[index];
        bool selected = state.selectedAssetIds.contains(index);
        var image = Image(
          image: imageProvider,
        );

        var imagePaddingValue = selected ? 14.0 : 0.0;
        return GestureDetector(
          onLongPress: () => widget.onStickerLongPress(selected, index),
          onTap: () => widget.onStickerTap(selected, index),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              if (state.isSelecting && selected)
                Container(
                  color: context.colorScheme.primaryContainer.withAlpha(100),
                ),
              AnimatedPadding(
                padding: EdgeInsets.all(imagePaddingValue),
                duration: const Duration(milliseconds: 150),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(selected ? 12 : 0),
                  child: image,
                ),
              ),
              if (state.isSelecting)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      color:
                          selected ? context.colorScheme.primary : Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
