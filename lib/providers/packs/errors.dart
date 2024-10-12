import 'package:mime_flutter/config/error.dart';

class MixingAnimatedAssetsError extends AppError {
  MixingAnimatedAssetsError() : super("You can't mix animated and static stickers in the same pack.");
}

// Invalid pack size error must be between 3 and 30
class InvalidPackSizeError extends AppError {
  InvalidPackSizeError() : super("A pack must have between 3 and 30 stickers.");
}