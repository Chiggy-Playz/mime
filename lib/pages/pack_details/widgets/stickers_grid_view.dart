
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/config/constants.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';
import 'package:mime_flutter/models/pack.dart';
import 'package:mime_flutter/providers/pack_details/provider.dart';
import 'package:vibration/vibration.dart';

class StickersGridView extends ConsumerStatefulWidget {
  const StickersGridView({super.key, required this.pack});

  final PackModel pack;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _StickersGridViewState();
}

class _StickersGridViewState extends ConsumerState<StickersGridView> {
  PackModel get pack => widget.pack;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(packDetailsNotifierProvider);

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      children: List.generate(pack.assets.length, (index) {
        final asset = pack.assets[index];
        bool selected = state.selectedAssetIds.contains(index);
        var image = Image.file(asset.file());

        var imagePaddingValue = selected ? 14.0 : 0.0;
        return GestureDetector(
          onLongPress: () {
            // if already selected, do nothing
            if (selected) return;
            if (!state.isSelecting) {
              if (canVibrate) Vibration.vibrate(duration: 10);
              ref.read(packDetailsNotifierProvider.notifier).toggleSelecting();
            }
            ref
                .read(packDetailsNotifierProvider.notifier)
                .toggleAssetSelection(index);
          },
          onTap: () {
            // if not in select mode, do nothing
            if (!state.isSelecting) return;
            // if already selected, deselect
            ref
                .read(packDetailsNotifierProvider.notifier)
                .toggleAssetSelection(index);
          },
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

