import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscordLoginView extends StatefulWidget {
  const DiscordLoginView({super.key});

  @override
  State<DiscordLoginView> createState() => _DiscordLoginViewState();
}

class _DiscordLoginViewState extends State<DiscordLoginView> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: () async {
          await Supabase.instance.client.auth.signInWithOAuth(
            OAuthProvider.discord,
            redirectTo: "com.chiggy.mime://home",
            // Launch the auth screen in a new webview on mobile.
            authScreenLaunchMode: LaunchMode.externalApplication,
          );
        },
        icon: const Padding(
          padding: EdgeInsets.all(4.0),
          child: Image(
            image: AssetImage("assets/icons/discord_icon.png"),
            height: 32,
          ),
        ),
        label: const Text("Login with Discord"),
      ),
    );
  }
}
