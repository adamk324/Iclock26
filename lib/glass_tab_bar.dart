import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class GlassTabBarItem {
  const GlassTabBarItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class GlassTabBar extends StatefulWidget {
  const GlassTabBar({
    required this.items,
    required this.currentIndex,
    required this.onChanged,
    required this.settingsSelected,
    required this.onSettingsPressed,
    super.key,
  })  : assert(items.length > 0),
        assert(currentIndex >= 0 && currentIndex < items.length);

  final List<GlassTabBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final bool settingsSelected;
  final VoidCallback onSettingsPressed;

  @override
  State<GlassTabBar> createState() => _GlassTabBarState();
}

class _GlassTabBarState extends State<GlassTabBar> {
  static const double _height = 52;
  static const double _inset = 4;
  static const double _radius = 26;

  late int _localIndex = widget.currentIndex;
  late bool _localSettingsSelected = widget.settingsSelected;
  int? _dragSelection;
  bool _dragStartedInSettings = false;

  @override
  void didUpdateWidget(covariant GlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _localIndex = widget.currentIndex;
    _localSettingsSelected = widget.settingsSelected;
  }

  void _selectTab(int index) {
    if (!_localSettingsSelected && index == _localIndex) return;

    _localIndex = index;
    _localSettingsSelected = false;
    HapticFeedback.selectionClick();
    widget.onChanged(index);
  }

  void _selectAt(double x, double width) {
    final double contentWidth = width - _inset * 2;
    if (contentWidth <= 0) return;

    final int index = ((x - _inset) / contentWidth * widget.items.length)
        .floor()
        .clamp(0, widget.items.length - 1)
        .toInt();
    final bool changesTab = _dragSelection == null
        ? (_dragStartedInSettings || index != _localIndex)
        : index != _dragSelection;
    if (!changesTab) return;

    _dragSelection = index;
    _selectTab(index);
  }

  void _startDragging(DragStartDetails details, double width) {
    _dragSelection = null;
    _dragStartedInSettings = _localSettingsSelected;
    _selectAt(details.localPosition.dx, width);
  }

  void _stopDragging(DragEndDetails details) {
    _dragSelection = null;
    _dragStartedInSettings = false;
  }

  void _openSettings() {
    if (_localSettingsSelected) return;
    _localSettingsSelected = true;
    HapticFeedback.selectionClick();
    widget.onSettingsPressed();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double tabWidth =
                    (constraints.maxWidth - _inset * 2) / widget.items.length;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) =>
                      _startDragging(details, constraints.maxWidth),
                  onPanUpdate: (details) =>
                      _selectAt(details.localPosition.dx, constraints.maxWidth),
                  onPanEnd: _stopDragging,
                  onPanCancel: () {
                    _dragSelection = null;
                    _dragStartedInSettings = false;
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_radius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0x40262628),
                          borderRadius: BorderRadius.circular(_radius),
                          border: Border.all(
                            color: const Color(0x33FFFFFF),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            if (!widget.settingsSelected)
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                left: _inset + tabWidth * widget.currentIndex,
                                top: _inset,
                                bottom: _inset,
                                width: tabWidth,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0x2EFFFFFF),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(_inset),
                              child: Row(
                                children: [
                                  for (var index = 0;
                                      index < widget.items.length;
                                      index++)
                                    Expanded(
                                      child: _TabItem(
                                        item: widget.items[index],
                                        selected: !widget.settingsSelected &&
                                            index == widget.currentIndex,
                                        onTap: () => _selectTab(index),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          _GlassSettingsButton(
            selected: widget.settingsSelected,
            onPressed: _openSettings,
          ),
        ],
      ),
    );
  }
}

class _GlassSettingsButton extends StatelessWidget {
  const _GlassSettingsButton({
    required this.selected,
    required this.onPressed,
  });

  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onPressed,
            color: const Color(0x40262628),
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x33FFFFFF),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.settings,
                size: 22,
                color: selected
                    ? CupertinoColors.systemOrange
                    : CupertinoColors.systemGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final GlassTabBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color =
        selected ? CupertinoColors.systemOrange : CupertinoColors.systemGrey;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Icon(item.icon, size: 22, color: color),
        ),
      ),
    );
  }
}
