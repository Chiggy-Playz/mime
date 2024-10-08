import 'package:flutter/material.dart';

class DialogWithTextfield extends StatefulWidget {
  const DialogWithTextfield({
    super.key,
    required this.title,
    required this.labelText,
    required this.hintText,
    required this.validator,
    this.icon,
    this.initialValue = "",
    this.positiveButtonText = "Save",
    this.negativeButtonText = "Cancel",
  });

  final String title;
  final String hintText;
  final String labelText;
  final String? Function(String?) validator;
  final String initialValue;
  final String positiveButtonText;
  final String negativeButtonText;
  final IconData? icon;

  @override
  State<DialogWithTextfield> createState() => _DialogWithTextfieldState();
}

class _DialogWithTextfieldState extends State<DialogWithTextfield> {
  final _formKey = GlobalKey<FormState>();
  String value = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: widget.icon != null ? Icon(widget.icon) : null,
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          onChanged: (value) {
            setState(() {
              this.value = value;
            });
          },
          initialValue: widget.initialValue,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
          ),
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(widget.negativeButtonText),
        ),
        TextButton(
          onPressed: () {
            // Validate input
            if (!_formKey.currentState!.validate()) {
              return;
            }
            // Send value
            Navigator.of(context).pop(value);
          },
          child: Text(widget.positiveButtonText),
        ),
      ],
    );
  }
}
