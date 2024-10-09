import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/pages/home/widgets/sticker_pack_list_view.dart';
import 'package:mime_flutter/providers/packs/provider.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  static const routePath = "/home";
  static const routeName = "Home";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  @override
  Widget build(BuildContext context) {
    return ref.watch(packsNotifierProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_a, __bb) => Center(
            child: Text(
                "Ooops, an error occurred. Try restarting the app?: $_a, $__bb"),
          ),
          data: (packs) {
            return StickerPackListView(packs: packs);
          },
        );
  }
}
