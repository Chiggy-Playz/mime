import 'package:flutter/material.dart';
import 'package:mime_flutter/models/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'provider.g.dart';

@Riverpod()
class SettingsNotifier extends _$SettingsNotifier {
  SharedPreferences? prefs;

  @override
  Future<SettingsModel> build() async {
    prefs ??= await SharedPreferences.getInstance();
    final settingsJson = prefs!.getString("preferences");

    SettingsModel settings = SettingsModel();

    if (settingsJson != null) {
      settings = SettingsModel.fromJsonString(settingsJson);
    }

    return settings;
  }

  Future<void> save() async {
    await prefs!.setString("preferences", state.value!.toJsonString());
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = AsyncData(state.value!.copyWith(themeMode: themeMode));
    await save();
  }

  Future<void> setExternalStickersPath(String? path) async {
    state = AsyncData(state.value!.copyWith(externalStickersStoragePath: path));
    await save();
  }

  Future<void> restoreSettings(SettingsModel settings) async {
    state = AsyncData(settings);
    await save();
  }
}
