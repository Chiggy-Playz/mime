import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/models/pack.dart';
import 'package:mime_flutter/pages/home/widgets/sticker_pack_preview.dart';
import 'package:mime_flutter/pages/pack_details/page.dart';
import 'package:mime_flutter/widgets/info_filler.dart';
import 'package:go_router/go_router.dart';

class StickerPackListView extends ConsumerStatefulWidget {
  const StickerPackListView({super.key, required this.packs});

  final List<PackModel> packs;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _StickerPackListViewState();
}

class _StickerPackListViewState extends ConsumerState<StickerPackListView> {
  List<PackModel> get packs => widget.packs;

  @override
  Widget build(BuildContext context) {
    return packs.isEmpty
        ? const InfoFillerWidget(
            icon: Icons.image_not_supported,
            title: "No packs yet",
            subtitle: "Get started by creating a new pack!",
          )
        : ListView.builder(
            primary: false,
            physics: const AlwaysScrollableScrollPhysics(),
            key: UniqueKey(),
            itemCount: packs.length,
            itemBuilder: (context, index) {
              final pack = packs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  elevation: 8,
                  child: InkWell(
                    onTap: () {
                      context.pushNamed(
                        PackDetailsPage.routeName,
                        pathParameters: {"id": pack.id},
                      );
                    },
                    child: Column(
                      children: [
                        ListTile(
                          leading: Image(
                            image: pack.iconId == null
                                ? const AssetImage(
                                    "assets/icons/icon.png",
                                  )
                                : FileImage(pack.iconFile()),
                            width: 48,
                            height: 48,
                          ),
                          title: Text(
                            pack.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          subtitle: Text("${pack.assets.length} stickers"),
                        ),
                        if (pack.assets.isNotEmpty)
                          StickerPackPreview(
                            pack: pack,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }
}
