import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_colors.dart';
import 'alarm_service.dart';
import 'nightstand_screen.dart';
import 'personalization_controls.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.controller,
    required this.onRunSetupAgain,
    required this.alarmService,
    super.key,
  });

  final SettingsController controller;
  final Future<void> Function() onRunSetupAgain;
  final AlarmService alarmService;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Settings'),
          backgroundColor: AppColors.of(context).background,
          border: null,
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              CupertinoListSection.insetGrouped(
                header: const Text('Appearance'),
                backgroundColor: AppColors.of(context).background,
                children: [
                  CupertinoListTile(
                    title: const Text('Theme'),
                    trailing: ThemeModePicker(
                      value: controller.themeMode,
                      onChanged: controller.setThemeMode,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Accent color'),
                        const SizedBox(height: 14),
                        AccentColorPicker(
                          selectedIndex: controller.accentIndex,
                          onSelected: controller.setAccentIndex,
                        ),
                      ],
                    ),
                  ),
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
                              style: TextStyle(
                                color: AppColors.of(context).secondaryText,
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
                header: const Text('Alarms'),
                backgroundColor: AppColors.of(context).background,
                children: [
                  CupertinoListTile(
                    title: const Text('Installation type'),
                    additionalInfo: Text(_installTypeLabel(controller.installType)),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => _chooseInstallType(context),
                  ),
                  CupertinoListTile(
                    title: const Text('Ring alarms inside the app'),
                    trailing: CupertinoSwitch(
                      value: controller.inAppAlarmRing,
                      onChanged: controller.setInAppAlarmRing,
                    ),
                  ),
                  CupertinoListTile(
                    title: const Text('Run setup again'),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () async {
                      controller.resetSetup();
                      await onRunSetupAgain();
                    },
                  ),
                ],
              ),
              CupertinoListSection.insetGrouped(
                header: const Text('Feedback'),
                backgroundColor: AppColors.of(context).background,
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
                header: const Text('Nightstand'),
                backgroundColor: AppColors.of(context).background,
                children: [
                  CupertinoListTile(
                    title: const Text('Nightstand'),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => Navigator.of(context).push<void>(
                      CupertinoPageRoute<void>(
                        builder: (context) => NightstandScreen(
                          controller: controller,
                          alarmService: alarmService,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              CupertinoListSection.insetGrouped(
                header: const Text('About'),
                backgroundColor: AppColors.of(context).background,
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

  String _installTypeLabel(InstallType? type) {
    switch (type) {
      case InstallType.trollStore:
        return 'TrollStore';
      case InstallType.standard:
        return 'Normal';
      case null:
        return 'Not selected';
    }
  }

  Future<void> _chooseInstallType(BuildContext context) {
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Installation type'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              controller.setInstallType(InstallType.trollStore);
              Navigator.of(context).pop();
            },
            child: const Text('TrollStore'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              controller.setInstallType(InstallType.standard);
              Navigator.of(context).pop();
            },
            child: const Text('Normal (App Store, TestFlight, or sideloaded)'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
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
      navigationBar: CupertinoNavigationBar(
        middle: Text('Legal notice'),
        previousPageTitle: 'Settings',
        backgroundColor: AppColors.of(context).background,
        border: null,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(
            _notice,
            style: TextStyle(
              color: AppColors.of(context).primaryText,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
