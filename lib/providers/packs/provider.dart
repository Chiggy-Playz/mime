import 'dart:convert';

import 'package:mime_flutter/models/pack.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'provider.g.dart';

@Riverpod()
class PacksNotifier extends _$PacksNotifier {
  SharedPreferences? prefs;

  @override
  Future<List<PackModel>> build() async {
    prefs ??= await SharedPreferences.getInstance();

    final packsJson = prefs!.getString("packs");

    if (packsJson != null) {
      final List<dynamic> packs = jsonDecode(packsJson);
      return packs.map((e) => PackModel.fromJson(e)).toList();
    }

    return [];
  }

  Future<void> createPack(String name) async {
    state = AsyncData(
      [
        ...state.value!,
        PackModel(name: name, assets: []),
      ],
    );
    await save();
  }

  Future<void> save() async {
    final packs = state.value!.map((e) => e.toJson()).toList();
    await prefs!.setString("packs", jsonEncode(packs));
  }
}
