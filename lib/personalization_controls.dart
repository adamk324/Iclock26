import 'package:flutter/cupertino.dart';

import 'app_colors.dart';
import 'settings_controller.dart';

class ThemeModePicker extends StatelessWidget {
  const ThemeModePicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ClockThemeMode value;
  final ValueChanged<ClockThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<ClockThemeMode>(
      groupValue: value,
      onValueChanged: (mode) {
        if (mode != null) onChanged(mode);
      },
      children: const <ClockThemeMode, Widget>{
        ClockThemeMode.system: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('System'),
        ),
        ClockThemeMode.light: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('Light'),
        ),
        ClockThemeMode.dark: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('Dark'),
        ),
      },
    );
  }
}

class AccentColorPicker extends StatelessWidget {
  const AccentColorPicker({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List<Widget>.generate(
        AppColors.accentPalette.length,
        (index) {
          final Color color = AppColors.accentPalette[index];
          final bool selected = index == selectedIndex;
          return GestureDetector(
            key: ValueKey('accent-color-$index'),
            onTap: () => onSelected(index),
            child: Semantics(
              button: true,
              selected: selected,
              label: 'Accent color ${index + 1}',
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: selected
                      ? Border.all(
                          color: AppColors.of(context).primaryText,
                          width: 2,
                        )
                      : null,
                ),
                child: selected
                    ? Icon(
                        CupertinoIcons.check_mark,
                        color: index == 6
                            ? CupertinoColors.black
                            : CupertinoColors.white,
                        size: 16,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
