import 'package:flutter/material.dart';
import 'package:mime_flutter/widgets/primary_title_text.dart';


class SettingsGroupWidget extends StatelessWidget {
  const SettingsGroupWidget({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const SizedBox.shrink(),
          title: PrimaryTitleText(title: title),
        ),
        ...children,
      ],
    );
  }
}
