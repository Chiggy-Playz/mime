import 'package:flutter/material.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';

class ConfirmationDialog extends StatefulWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = "Confirm",
    this.cancelText = "Cancel",
    this.icon = Icons.warning,
    this.dangerous = false,
  });

  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData icon;
  final bool dangerous;

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(widget.icon),
      title: Text(widget.title),
      content: Text(widget.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.cancelText),
        ),
        if (!widget.dangerous)
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(widget.confirmText),
          ),
        if (widget.dangerous)
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: context.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(widget.confirmText),
          )
      ],
    );
  }
}

Future<bool> showConfirmationDialog({
  required String title,
  required String message,
  required BuildContext context,
  String confirmText = "Confirm",
  String cancelText = "Cancel",
  IconData icon = Icons.warning,
  bool dangerous = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ConfirmationDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon,
      dangerous: dangerous,
    ),
  );
  return result ?? false;
}
