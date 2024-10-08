import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mime_flutter/providers/packs/provider.dart';
import 'package:mime_flutter/widgets/dialog_with_textfield.dart';

const destinations = [
  NavigationDestination(icon: Icon(Icons.home), label: "Home"),
  NavigationDestination(icon: Icon(Icons.settings), label: "Settings"),
];

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  Future<void> createPressed() async {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(destinations[navigationShell.currentIndex].label),
      ),
      body: navigationShell,
      floatingActionButton: navigationShell.currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final name = await showDialog<String>(
                  context: context,
                  builder: (context) => DialogWithTextfield(
                    title: "Create Pack",
                    labelText: "Name",
                    hintText: "Enter a name",
                    validator: (value) {
                      // Alpha numeric only, spaces allowed, 3-128 characters
                      final valid = RegExp(r"^[a-zA-Z0-9 ]{3,128}$")
                          .hasMatch(value ?? "");
                      return valid ? null : "Invalid name";
                    },
                    positiveButtonText: "Create",
                  ),
                );
                if (name == null) return;

                await ref.read(packsNotifierProvider.notifier).createPack(name);
              },
              tooltip: "Create",
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        destinations: destinations,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
