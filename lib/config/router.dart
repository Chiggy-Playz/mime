import 'package:go_router/go_router.dart';
import 'package:mime_flutter/pages/home_shell.dart';
import 'package:mime_flutter/pages/home/view.dart';
import 'package:mime_flutter/pages/settings/view.dart';

final router = GoRouter(
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
    )
  ],
);
