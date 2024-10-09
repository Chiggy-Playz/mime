import 'package:mime_flutter/config/error.dart';

class MixingAnimatedAssetsError extends AppError {
  MixingAnimatedAssetsError() : super("You can't mix animated and static assets in the same pack.");
}