import 'package:flutter/material.dart';
import 'package:mime_flutter/config/extensions/extensions.dart';

class PrimaryTitleText extends StatelessWidget {
  const PrimaryTitleText({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: context.textTheme.bodyMedium!.copyWith(
          color: context.colorScheme.primary, fontWeight: FontWeight.bold),
    );
  }
}

class PrimaryTitleListTile extends StatelessWidget {
  const PrimaryTitleListTile({super.key, required this.title, this.leading});

  final String title;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: PrimaryTitleText(title: title),
      dense: true,
    );
  }
}
