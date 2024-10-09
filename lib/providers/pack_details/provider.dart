import 'package:mime_flutter/providers/pack_details/state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'provider.g.dart';

@Riverpod()
class PackDetailsNotifier extends _$PackDetailsNotifier {
  @override
  PackDetailsState build() {
    return const PackDetailsState(
      isEditing: false,
      isSelecting: false,
      isImporting: false,
      selectedAssetIds: {},
    );
  }

  void toggleSelecting() {
    state = state.copyWith(isSelecting: !state.isSelecting);
  }

  void toggleEditing() {
    state = state.copyWith(isEditing: !state.isEditing);
  }

  void toggleImporting() {
    state = state.copyWith(isImporting: !state.isImporting);
  }

  void toggleAssetSelection(String assetId) {
    final selectedAssetIds = state.selectedAssetIds.toSet();
    if (selectedAssetIds.contains(assetId)) {
      selectedAssetIds.remove(assetId);
    } else {
      selectedAssetIds.add(assetId);
    }

    state = state.copyWith(
      selectedAssetIds: selectedAssetIds,
      isSelecting: selectedAssetIds.isNotEmpty,
    );
  }

  void clearSelection() {
    state = state.copyWith(selectedAssetIds: {});
  }

  void selectAll(List<String> assetIds) {
    state = state.copyWith(selectedAssetIds: assetIds.toSet());
  }
}
