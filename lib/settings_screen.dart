import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import 'settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.controller,
    super.key,
  });

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Settings'),
          backgroundColor: CupertinoColors.black,
          border: null,
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              CupertinoListSection.insetGrouped(
                header: const Text('Appearance'),
                backgroundColor: CupertinoColors.black,
                children: [
                  CupertinoListTile(
                    title: const Text('Glass transparency'),
                    trailing: CupertinoSwitch(
                      value: controller.glassTransparencyEnabled,
                      onChanged: controller.setGlassTransparencyEnabled,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Transparency amount'),
                            Text(
                              '${(controller.transparencyAmount * 100).round()}%',
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                        CupertinoSlider(
                          value: controller.transparencyAmount,
                          onChanged: controller.glassTransparencyEnabled
                              ? controller.setTransparencyAmount
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              CupertinoListSection.insetGrouped(
                header: const Text('Feedback'),
                backgroundColor: CupertinoColors.black,
                children: [
                  CupertinoListTile(
                    title: const Text('Vibration'),
                    trailing: CupertinoSwitch(
                      value: controller.vibrationEnabled,
                      onChanged: controller.setVibrationEnabled,
                    ),
                  ),
                ],
              ),
              CupertinoListSection.insetGrouped(
                header: const Text('About'),
                backgroundColor: CupertinoColors.black,
                children: [
                  CupertinoListTile(
                    title: const Text('Source code on GitHub'),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => _openSource(context),
                  ),
                  CupertinoListTile(
                    title: const Text('Legal notice'),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.of(context).push<void>(
                        CupertinoPageRoute<void>(
                          builder: (context) => const _LegalNoticeScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSource(BuildContext context) async {
    final Uri uri = Uri.parse('https://github.com/adamk324/Iclock26');
    try {
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        await _showLaunchError(context);
      }
    } on Exception {
      if (context.mounted) await _showLaunchError(context);
    }
  }

  Future<void> _showLaunchError(BuildContext context) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Unable to open link'),
        content: const Text('The GitHub page could not be opened.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _LegalNoticeScreen extends StatelessWidget {
  const _LegalNoticeScreen();

  static const String _notice =
      'This is an unofficial, independent, open-source hobby project. It is '
      'not affiliated with, endorsed by, or sponsored by Apple Inc. Apple, '
      'iOS, iPhone, and Clock are trademarks of Apple Inc., used here only to '
      'describe what the app resembles. The app uses no Apple code or assets. '
      'It is provided as is, without warranty of any kind. Alarms and timers '
      'may not be reliable; do not depend on them for anything important.';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Legal notice'),
        previousPageTitle: 'Settings',
        backgroundColor: CupertinoColors.black,
        border: null,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: const Text(
            _notice,
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
