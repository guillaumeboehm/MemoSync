import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Opens a dialog with the app info
Future<void> showAbout(BuildContext context) async {
  final pi = await PackageInfo.fromPlatform();

  showAboutDialog(
    context: context,
    applicationIcon: SvgPicture.asset(
      'assets/resources/logos/svg/Full_logo.svg',
    ),
    applicationName: 'MemoSync',
    applicationVersion: '${pi.version}-${pi.buildNumber}',
    applicationLegalese: '\u{a9} 2022 BOEHM Guillaume',
    children: <Widget>[
      const SizedBox(height: 24),
      RichText(
        text: const TextSpan(
          text: 'some text',
        ),
      ),
    ],
  );
}
