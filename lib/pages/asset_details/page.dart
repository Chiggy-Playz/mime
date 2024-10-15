import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mime_flutter/models/asset.dart';
import 'package:mime_flutter/pages/tag_editor/page.dart';
import 'package:mime_flutter/providers/packs/provider.dart';

class AssetDetailsPage extends ConsumerStatefulWidget {
  const AssetDetailsPage({
    super.key,
    required this.packId,
    required this.assetId,
  });

  static const routePath = "/pack/:packId/assets/:assetId";
  static const routeName = "Asset Details";

  final String packId;
  final String assetId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AssetDetailsPageState();
}

class _AssetDetailsPageState extends ConsumerState<AssetDetailsPage> {
  late AssetModel asset;
  String name = "";
  Set<String> tags = {};

  @override
  Widget build(BuildContext context) {
    final pack = ref
        .watch(packsNotifierProvider)
        .value!
        .where((pack) => pack.id == widget.packId)
        .firstOrNull;

    if (pack == null) {
      return const Center(
        child: Text("Pack not found"),
      );
    }

    asset = pack.assets.firstWhere((asset) => asset.id == widget.assetId);

    // Not yet initialized
    if (name.isEmpty) {
      name = asset.name.trim().replaceAll(".webp", "");
      tags = Set.from(asset.tags);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sticker Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(16),
            Center(
              child: Image.file(
                asset.file(),
                width: 128,
                height: 128,
              ),
            ),
            const Gap(16),
            TextFormField(
              initialValue: name,
              decoration: const InputDecoration(
                labelText: "Name",
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter a name";
                }

                // Only alphanumeric characters and spaces
                if (!RegExp(r"^[a-zA-Z0-9 ]+$").hasMatch(value)) {
                  return "Only alphanumeric characters and spaces are allowed";
                }

                // Max 128 characters
                if (value.length > 128) {
                  return "Name is too long";
                }

                return null;
              },
              onChanged: (value) {
                setState(() {
                  name = value;
                });
              },
              onSaved: (value) {
                name = value!;
              },
            ),
            const Gap(16),
            Text(
              "Tags",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              children: (tags
                          .map<Widget>(
                            (tag) => Chip(
                              label: Text(tag),
                              onDeleted: () {
                                setState(() {
                                  tags.remove(tag);
                                });
                              },
                            ),
                          )
                          .toList() +
                      [
                        ActionChip(
                          avatar: const Icon(Icons.edit),
                          label: const Text("Edit"),
                          onPressed: () async {
                            final newTags =
                                await context.pushNamed<Set<String>>(
                              TagEditorPage.routeName,
                              queryParameters: {
                                "tags": tags.join(","),
                              },
                            );

                            if (newTags == null) return;
                            setState(() {
                              tags = newTags;
                            });
                          },
                        )
                      ])
                  .map(
                    (widget) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: widget,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      floatingActionButton: name != asset.name.replaceAll(".webp", "") ||
              tags.difference(asset.tags).isNotEmpty
          ? FloatingActionButton(
              onPressed: () async {
                await ref.read(packsNotifierProvider.notifier).updateAssetName(
                      widget.packId,
                      widget.assetId,
                      name,
                    );

                final tagsAdded = tags.difference(asset.tags);
                final tagsRemoved = asset.tags.difference(tags);

                await ref.read(packsNotifierProvider.notifier).updateAssetTags(
                      widget.packId,
                      [widget.assetId],
                      tagsAdded,
                      tagsRemoved,
                    );

                if (!context.mounted) return;
                context.pop();
              },
              child: const Icon(Icons.save),
            )
          : null,
    );
  }
}
