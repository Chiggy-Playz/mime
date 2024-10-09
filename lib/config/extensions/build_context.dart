import 'package:flutter/material.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';

extension BuildContextExtensions on BuildContext {
  // SnackBar
  void showSnackBar(String message, {bool floating = false}) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message),
      behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
    ));
  }

  // Error SnackBar
  void showErrorSnackBar(String message,
      {bool floating = false, SnackBarAction? action}) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(color: colorScheme.onError)),
      backgroundColor: colorScheme.error,
      behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
      action: action,
    ));
  }
}
