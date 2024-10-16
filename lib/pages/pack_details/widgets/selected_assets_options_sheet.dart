import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';
import 'package:go_router/go_router.dart';
import 'package:mime_flutter/models/pack.dart';
import 'package:mime_flutter/pages/tag_editor/page.dart';
import 'package:mime_flutter/providers/pack_details/provider.dart';
import 'package:mime_flutter/providers/packs/provider.dart';
import 'package:mime_flutter/widgets/labeled_icon.dart';
import 'package:share_plus/share_plus.dart';

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
                        // if (state.selectedAssetIds.length != 1)
                        LabeledIcon(
                          iconData: Icons.label,
                          label: "Edit \nTags",
                          onTap: editTagsPressed,
                        ),
                        LabeledIcon(
                          iconData: Icons.delete,
                          label: "Remove",
                          onTap: removeAssetsPressed,
                        ),
                        if (state.selectedAssetIds.length == 1)
                          LabeledIcon(
                            iconData: Icons.image,
                            label: "Set as \nPack Icon",
                            onTap: setPackIconPressed,
                          ),
                        LabeledIcon(
                          iconData: Icons.share,
                          label: "Share",
                          onTap: sharePressed,
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

  Future<void> setPackIconPressed() async {
    final asset = pack
        .assets[ref.read(packDetailsNotifierProvider).selectedAssetIds.first];

    if (asset.animated) {
      context.showSnackBar("Animated images are not supported");
      return;
    }

    await ref
        .read(packsNotifierProvider.notifier)
        .setPackIcon(pack.id, asset.id);
    ref.read(packDetailsNotifierProvider.notifier).toggleSelecting();
  }

  Future<void> editTagsPressed() async {
    final notifier = ref.read(packsNotifierProvider.notifier);

    // First, find all the common tags of the selected assets
    final selectedAssets = ref
        .read(packDetailsNotifierProvider)
        .selectedAssetIds
        .map((index) => pack.assets[index])
        .toList();

    // Fold the tags of the selected assets to find the common tags
    final commonTags = selectedAssets.fold<Set<String>>(
      selectedAssets.first.tags,
      (commonTags, asset) {
        return commonTags.intersection(asset.tags);
      },
    );

    // Then, open the tag editor with the common tags
    final newTags = await context.pushNamed<Set<String>>(
      TagEditorPage.routeName,
      queryParameters: {
        "tags": commonTags.join(","),
      },
    );

    if (newTags == null) return;

    // Figure out which tags to add and remove
    final tagsToAdd = newTags.difference(commonTags);
    final tagsToRemove = commonTags.difference(newTags);

    // Update the tags of the selected assets
    await notifier.updateAssetTags(
      pack.id,
      selectedAssets.map((asset) => asset.id).toList(),
      tagsToAdd,
      tagsToRemove,
    );
  }

  Future<void> sharePressed() async {
    final selectedAssets = ref
        .read(packDetailsNotifierProvider)
        .selectedAssetIds
        .map((index) => pack.assets[index])
        .toList();

    await Share.shareXFiles(
        selectedAssets.map((asset) => asset.xFile()).toList());
  }
}
