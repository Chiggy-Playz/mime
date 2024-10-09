import 'package:dart_mappable/dart_mappable.dart';

part 'state.mapper.dart';

@MappableClass()
class PackDetailsState with PackDetailsStateMappable {
  final bool isSelecting;
  final bool isEditing;
  final bool isImporting;
  final Set<String> selectedAssetIds;

  const PackDetailsState({
    required this.isSelecting,
    required this.isEditing,
    required this.isImporting,
    required this.selectedAssetIds,
  });

  bool get isViewing => !isSelecting && !isEditing;
}
