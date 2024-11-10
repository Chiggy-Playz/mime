import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mime_flutter/config/constants.dart';
import 'package:mime_flutter/models/discord_asset.dart';
import 'package:mime_flutter/pages/discord/login_view.dart';
import 'package:mime_flutter/providers/pack_details/provider.dart';
import 'package:mime_flutter/widgets/stickers_grid_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

final supabase = Supabase.instance.client;

class DiscordAssetsPage extends ConsumerStatefulWidget {
  const DiscordAssetsPage({super.key});

  static const routePath = '/discord/assets';
  static const routeName = 'Discord Assets';

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      DiscordAssetsPageState();
}

class DiscordAssetsPageState extends ConsumerState<DiscordAssetsPage> {
  List<DiscordAssetModel> discordAssets = [];

  @override
  Widget build(BuildContext context) {
    final future =
        supabase.from('user_assets').select('assets(id, name, animated, type)');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discord Assets'),
        actions: [
          IconButton(
              onPressed: () async {
                launchUrl(Uri.parse(mimeBotInviteUrl));
              },
              icon: const Icon(Icons.smart_toy)),
          if (supabase.auth.currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await supabase.auth.signOut();
                if (!mounted) return;
                setState(() {});
              },
            ),
        ],
      ),
      body: supabase.auth.currentUser == null
          ? const DiscordLoginView()
          : FutureBuilder(
              future: future,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                  case ConnectionState.active:
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  case ConnectionState.done:
                    discordAssets = snapshot.data!.map((element) {
                      return DiscordAssetModel.fromJson(element["assets"]);
                    }).toList();
                    return Consumer(
                      builder: (context, ref, child) {
                        final state = ref.watch(packDetailsNotifierProvider);
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: StickersGridView(
                            imageProviders: discordAssets
                                .map((asset) => NetworkImage(asset.url))
                                .toList(),
                            onStickerTap: (selected, index) async {
                              if (!state.isSelecting) {
                                context.pop([discordAssets[index]]);
                                return;
                              }
                              ref
                                  .read(packDetailsNotifierProvider.notifier)
                                  .toggleAssetSelection(index);
                            },
                            onStickerLongPress: (selected, index) async {
                              // if already selected, do nothing
                              if (selected) return;
                              if (!state.isSelecting) {
                                if (canVibrate) Vibration.vibrate(duration: 10);
                                ref
                                    .read(packDetailsNotifierProvider.notifier)
                                    .toggleSelecting();
                              }
                              ref
                                  .read(packDetailsNotifierProvider.notifier)
                                  .toggleAssetSelection(index);
                            },
                          ),
                        );
                      },
                    );
                }
              },
            ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(packDetailsNotifierProvider);
          return !state.isSelecting
              ? const SizedBox.shrink()
              : FloatingActionButton(
                  heroTag: "download",
                  onPressed: () {
                    context.pop(state.selectedAssetIds
                        .map(
                          (index) => discordAssets[index],
                        )
                        .toList());

                    ref
                        .read(packDetailsNotifierProvider.notifier)
                        .toggleSelecting();
                  },
                  child: const Icon(Icons.download),
                );
        },
      ),
    );
  }
}
