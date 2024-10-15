import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime_flutter/config/constants.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';
import 'package:mime_flutter/config/utils.dart';
import 'package:mime_flutter/models/asset.dart';
import 'package:mime_flutter/models/pack.dart';
import 'package:mime_flutter/providers/pack_details/provider.dart';
import 'package:mime_flutter/providers/packs/provider.dart';
import 'package:mime_flutter/widgets/dialog_with_textfield.dart';

class StickerPackHeader extends ConsumerStatefulWidget {
  const StickerPackHeader({super.key, required this.pack});

  final PackModel pack;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _StickerPackHeaderState();
}

class _StickerPackHeaderState extends ConsumerState<StickerPackHeader> {
  PackModel get pack => widget.pack;

  @override
  Widget build(BuildContext context) {
    bool isEditing = ref.watch(packDetailsNotifierProvider).isEditing;
    final image = Image(
      image: pack.iconId == null
          ? const AssetImage(
              "assets/icons/icon.png",
            )
          : FileImage(pack.iconFile()),
      width: 96,
      height: 96,
    );
    var imagePaddingValue = isEditing ? 14.0 : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isEditing)
              Container(
                color: context.colorScheme.primaryContainer.withAlpha(100),
              ),
            AnimatedPadding(
              padding: EdgeInsets.symmetric(horizontal: imagePaddingValue),
              duration: const Duration(milliseconds: 150),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isEditing ? 12 : 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: isEditing ? editIconClicked : null,
                  child: image,
                ),
              ),
            ),
            if (isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: IconButton.filled(
                    onPressed: editIconClicked,
                    icon: const Icon(Icons.edit),
                  ),
                ),
              ),
          ],
        ),
        const Gap(16),
        Flexible(
          child: InkWell(
            onTap: isEditing ? editNameClicked : null,
            child: Container(
              decoration: BoxDecoration(
                border: !isEditing
                    ? null
                    : Border.all(color: context.colorScheme.onSurface),
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.all(4.0),
              child: Text(
                pack.name,
                style: context.textTheme.headlineMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> editIconClicked() async {
    if (!ref.read(packDetailsNotifierProvider).isEditing) return;

    final ImagePicker picker = ImagePicker();
    final XFile? images = await picker.pickMedia();

    if (!mounted) return;
    if (images == null) {
      context.showSnackBar("No image selected");
      return;
    }

    final AssetModel asset = await convertXfileToAsset(images);

    if (!mounted) return;
    if (asset.animated) {
      context.showSnackBar("Animated images are not supported");
      return;
    }

    ref.read(packDetailsNotifierProvider.notifier).toggleImporting();

    await processAssetsInParallel([asset], AssetModel.directory, tempDir);

    await ref.read(packsNotifierProvider.notifier).setPackIcon(
          pack.id,
          asset.id,
        );
    ref.read(packDetailsNotifierProvider.notifier).toggleImporting();
  }

  Future<void> editNameClicked() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => DialogWithTextfield(
        title: "Edit Pack Name",
        labelText: "Name",
        hintText: "Enter a name",
        initialValue: pack.name,
        validator: (value) {
          // Alpha numeric only, spaces allowed, 3-128 characters
          final valid = RegExp(r"^[a-zA-Z0-9 ]{3,128}$").hasMatch(value ?? "");
          return valid ? null : "Invalid name";
        },
        positiveButtonText: "Save",
      ),
    );

    if (name == null) return;

    await ref
        .read(packsNotifierProvider.notifier)
        .setPackName(pack.id, name.trim());
  }
}
