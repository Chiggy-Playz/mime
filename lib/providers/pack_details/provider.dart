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
    state = state.copyWith(isSelecting: !state.isSelecting, selectedAssetIds: {});
  }

  void toggleEditing() {
    state = state.copyWith(isEditing: !state.isEditing);
  }

  void toggleImporting() {
    state = state.copyWith(isImporting: !state.isImporting);
  }

  void toggleAssetSelection(int assetIndex) {
    final selectedAssetIds = state.selectedAssetIds.toSet();
    if (selectedAssetIds.contains(assetIndex)) {
      selectedAssetIds.remove(assetIndex);
    } else {
      selectedAssetIds.add(assetIndex);
    }

    state = state.copyWith(
      selectedAssetIds: selectedAssetIds,
      isSelecting: selectedAssetIds.isNotEmpty,
    );
  }

  void clearSelection() {
    state = state.copyWith(selectedAssetIds: {});
  }

  void selectAll(List<int> assetIds) {
    state = state.copyWith(selectedAssetIds: assetIds.toSet());
  }
}
