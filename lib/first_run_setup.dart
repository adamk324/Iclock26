import 'package:flutter/cupertino.dart';

import 'alarm_service.dart';
import 'app_colors.dart';
import 'personalization_controls.dart';
import 'settings_controller.dart';

Future<void> showFirstRunSetup({
  required BuildContext context,
  required SettingsController controller,
  required AlarmService alarmService,
}) {
  return showCupertinoModalPopup<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _FirstRunSetupSheet(
      controller: controller,
      alarmService: alarmService,
    ),
  );
}

class _FirstRunSetupSheet extends StatefulWidget {
  const _FirstRunSetupSheet({
    required this.controller,
    required this.alarmService,
  });

  final SettingsController controller;
  final AlarmService alarmService;

  @override
  State<_FirstRunSetupSheet> createState() => _FirstRunSetupSheetState();
}

class _FirstRunSetupSheetState extends State<_FirstRunSetupSheet> {
  final PageController _pages = PageController();
  int _page = 0;
  InstallType? _installType;
  String? _testNotificationStatus;
  bool _sendingTestNotification = false;

  @override
  void initState() {
    super.initState();
    _installType = widget.controller.installType;
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_page == 1 && _installType == null) return;
    if (_page < 3) {
      setState(() => _page++);
      await _pages.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (_installType != null) {
      widget.controller.setInstallType(_installType!);
    }
    widget.controller.completeSetup();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _sendingTestNotification = true;
      _testNotificationStatus = null;
    });
    try {
      await widget.alarmService.scheduleTestNotification();
      if (!mounted) return;
      setState(() {
        _testNotificationStatus =
            'A notification is scheduled in 5 seconds. Lock your phone to '
            'check that it arrives.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _testNotificationStatus = 'Could not schedule: $error');
    } finally {
      if (mounted) setState(() => _sendingTestNotification = false);
    }
  }

  Widget _pageContent() {
    switch (_page) {
      case 0:
        return const _SetupIntro(
          title: 'Welcome to Clock*',
          subtitle:
              'An unofficial recreation inspired by the iOS Clock app, '
              'independent and not affiliated with Apple.',
          icon: CupertinoIcons.clock,
        );
      case 1:
        return _InstallChoicePage(
          selected: _installType,
          onSelected: (type) => setState(() => _installType = type),
        );
      case 2:
        return _CustomizeSetupPage(controller: widget.controller);
      default:
        final bool trollStore = _installType == InstallType.trollStore;
        return _AlarmSetupPage(
          description: trollStore
              ? 'Alarms use notifications when the app is closed. With '
                  'TrollStore, you can also enable in-app ringing while the '
                  'app is open.'
              : 'Alarms use notifications while the app is closed. You can '
                  'also enable in-app ringing in Settings while the app is '
                  'open.',
          sending: _sendingTestNotification,
          status: _testNotificationStatus,
          onTest: _sendTestNotification,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.of(context).background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).secondaryText,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _pageContentFor(0),
                  _pageContentFor(1),
                  _pageContentFor(2),
                  _pageContentFor(3),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                4,
                (index) => Container(
                  width: index == _page ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == _page
                        ? AppColors.of(context).primaryText
                        : AppColors.of(context).secondaryText,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _page == 1 && _installType == null
                      ? null
                      : _continue,
                  borderRadius: BorderRadius.circular(28),
                  child: Text(_page == 3 ? 'Finish' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageContentFor(int index) {
    if (_page != index) {
      if (index == 0) {
        return const _SetupIntro(
          title: 'Welcome to Clock*',
          subtitle:
              'An unofficial recreation inspired by iOS Clock, independent '
              'and not affiliated with Apple.',
          icon: CupertinoIcons.clock,
        );
      }
      if (index == 1) {
        return _InstallChoicePage(
          selected: _installType,
          onSelected: (type) => setState(() => _installType = type),
        );
      }
      if (index == 2) {
        return _CustomizeSetupPage(controller: widget.controller);
      }
      return const SizedBox.shrink();
    }
    return _pageContent();
  }
}

class _SetupIntro extends StatelessWidget {
  const _SetupIntro({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 58, color: CupertinoTheme.of(context).primaryColor),
          const SizedBox(height: 30),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.of(context).primaryText,
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.of(context).secondaryText,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomizeSetupPage extends StatelessWidget {
  const _CustomizeSetupPage({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Make it yours',
              style: TextStyle(
                color: AppColors.of(context).primaryText,
                fontSize: 30,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ThemeModePicker(
                value: controller.themeMode,
                onChanged: controller.setThemeMode,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Accent color',
              style: TextStyle(color: AppColors.of(context).secondaryText),
            ),
            const SizedBox(height: 14),
            AccentColorPicker(
              selectedIndex: controller.accentIndex,
              onSelected: controller.setAccentIndex,
            ),
            const SizedBox(height: 30),
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.of(context).secondaryButton,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.clock,
                  color: controller.accentColor,
                  size: 38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstallChoicePage extends StatelessWidget {
  const _InstallChoicePage({
    required this.selected,
    required this.onSelected,
  });

  final InstallType? selected;
  final ValueChanged<InstallType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How did you install this app?',
            style: TextStyle(
              color: AppColors.of(context).primaryText,
              fontSize: 27,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 26),
          _InstallCard(
            title: 'TrollStore',
            selected: selected == InstallType.trollStore,
            onTap: () => onSelected(InstallType.trollStore),
          ),
          const SizedBox(height: 12),
          _InstallCard(
            title: 'Normal (App Store, TestFlight, or sideloaded)',
            selected: selected == InstallType.standard,
            onTap: () => onSelected(InstallType.standard),
          ),
        ],
      ),
    );
  }
}

class _InstallCard extends StatelessWidget {
  const _InstallCard({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.of(context).secondaryButton,
          border: Border.all(
            color: selected
                ? CupertinoTheme.of(context).primaryColor
                : AppColors.of(context).separator,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: AppColors.of(context).primaryText),
              ),
            ),
            if (selected)
              Icon(
                CupertinoIcons.check_mark_circled_solid,
                color: CupertinoTheme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}

class _AlarmSetupPage extends StatelessWidget {
  const _AlarmSetupPage({
    required this.description,
    required this.sending,
    required this.status,
    required this.onTest,
  });

  final String description;
  final bool sending;
  final String? status;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alarms',
            style: TextStyle(
              color: AppColors.of(context).primaryText,
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              color: AppColors.of(context).secondaryText,
              fontSize: 16,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            onPressed: sending ? null : onTest,
            child: sending
                ? const CupertinoActivityIndicator()
                : const Text('Send test notification'),
          ),
          if (status != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                status!,
                style: TextStyle(
                  color: AppColors.of(context).secondaryText,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
