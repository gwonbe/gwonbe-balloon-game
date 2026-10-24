import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionText extends StatelessWidget {
  final Color color;
  final List<Shadow> shadows;

  const AppVersionText({
    super.key,
    required this.color,
    this.shadows = const [],
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final info = snapshot.data!;

        final formattedVersion = info.version
          .split('.')
          .map((part) => part.padLeft(2, '0'))
          .join('.');

        return Text(
          formattedVersion,
          style: TextStyle(
            fontSize: 14,
            color: color,
            shadows: shadows,
          ),
        );
      },
    );
  }
}