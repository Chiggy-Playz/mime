import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class LabeledIcon extends StatelessWidget {
  const LabeledIcon(
      {super.key,
      required this.iconData,
      required this.label,
      required this.onTap});

  final IconData iconData;
  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(64),
        radius: 128,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
          child: Column(
            children: [
              Icon(iconData, size: 24),
              const Gap(8),
              Text(
                label,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
