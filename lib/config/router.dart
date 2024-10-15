import 'package:go_router/go_router.dart';
import 'package:mime_flutter/pages/home_shell.dart';
import 'package:mime_flutter/pages/home/view.dart';
import 'package:mime_flutter/pages/pack_details/page.dart';
import 'package:mime_flutter/pages/settings/view.dart';
import 'package:mime_flutter/pages/tag_editor/page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: "/home",
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: HomeView.routePath,
                name: HomeView.routeName,
                builder: (context, state) {
                  return const HomeView();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: SettingsView.routePath,
                name: SettingsView.routeName,
                builder: (context, state) {
                  return const SettingsView();
                },
              )
            ],
          )
        ],
      ),
      GoRoute(
        path: PackDetailsPage.routePath,
        name: PackDetailsPage.routeName,
        builder: (context, state) {
          return PackDetailsPage(
            id: state.pathParameters["id"]!,
          );
        },
      ),
      GoRoute(
        path: TagEditorPage.routePath,
        name: TagEditorPage.routeName,
        builder: (context, state) {
          final rawTags = state.uri.queryParameters["tags"]!;
          final Set<String> tags;
          if (rawTags.isEmpty) {
            tags = {};
          } else {
            tags = rawTags.split(",").toSet();
          }

          return TagEditorPage(
            tags: tags,
          );
        },
      ),
    ],
  );
}
