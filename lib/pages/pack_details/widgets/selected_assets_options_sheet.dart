import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';
import 'package:mime_flutter/models/pack.dart';
import 'package:mime_flutter/providers/pack_details/provider.dart';
import 'package:mime_flutter/providers/packs/provider.dart';
import 'package:mime_flutter/widgets/labeled_icon.dart';

class SelectedAssetsOptionsSheet extends ConsumerStatefulWidget {
  const SelectedAssetsOptionsSheet({super.key, required this.pack});

  final PackModel pack;

  @override
  ConsumerState<SelectedAssetsOptionsSheet> createState() =>
      _SelectedAssetsOptionsSheetState();
}

class _SelectedAssetsOptionsSheetState
    extends ConsumerState<SelectedAssetsOptionsSheet> {
  PackModel get pack => widget.pack;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(packDetailsNotifierProvider);

    return TweenAnimationBuilder(
      tween: Tween<double>(
        begin: 0.0,
        end: state.selectedAssetIds.isNotEmpty ? 0.16 : 0.0,
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return DraggableScrollableSheet(
          expand: false,
          minChildSize: 0.0,
          initialChildSize: value,
          builder: (context, controller) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Material(
                    color: Colors.transparent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        if (state.selectedAssetIds.length == 1)
                          LabeledIcon(
                            iconData: Icons.edit,
                            label: "Edit \nName",
                            onTap: () async {},
                          ),
                        LabeledIcon(
                          iconData: Icons.label,
                          label: "Edit \nTags",
                          onTap: () async {},
                        ),
                        LabeledIcon(
                          iconData: Icons.delete,
                          label: "Remove",
                          onTap: removeAssetsPressed,
                        ),
                        LabeledIcon(
                          iconData: Icons.share,
                          label: "Share",
                          onTap: () async {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> removeAssetsPressed() async {
    final assetsIds = ref.read(packDetailsNotifierProvider).selectedAssetIds;
    var assets = assetsIds.map((index) => pack.assets[index]).toList();

    await ref
        .read(packsNotifierProvider.notifier)
        .removeAssets(pack.id, assets);

    ref.read(packDetailsNotifierProvider.notifier).toggleSelecting();

    if (!mounted) return;

    final notifier = ref.read(packsNotifierProvider.notifier);

    context.showSnackBar(
      "Removed ${assets.length} stickers",
      action: SnackBarAction(
        label: "Undo",
        onPressed: () {
          notifier.addAssets(pack.id, assets);
        },
      ),
    );
  }
}
