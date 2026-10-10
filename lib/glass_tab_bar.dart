import 'dart:ui';

import 'package:flutter/cupertino.dart';

class GlassTabBarItem {
  const GlassTabBarItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    required this.items,
    required this.currentIndex,
    required this.onChanged,
    super.key,
  })  : assert(items.length > 0),
        assert(currentIndex >= 0 && currentIndex < items.length);

  final List<GlassTabBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const double _height = 68;
  static const double _inset = 5;
  static const double _radius = 32;

  void _selectAt(double x, double width) {
    final double contentWidth = width - _inset * 2;
    if (contentWidth <= 0) return;
    final int index = ((x - _inset) / contentWidth * items.length)
        .floor()
        .clamp(0, items.length - 1)
        .toInt();
    if (index != currentIndex) onChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double tabWidth =
              (constraints.maxWidth - _inset * 2) / items.length;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (details) =>
                _selectAt(details.localPosition.dx, constraints.maxWidth),
            onPanUpdate: (details) =>
                _selectAt(details.localPosition.dx, constraints.maxWidth),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xC91C1C1E),
                    borderRadius: BorderRadius.circular(_radius),
                    border: Border.all(
                      color: const Color(0x40FFFFFF),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        left: _inset + tabWidth * currentIndex,
                        top: _inset,
                        bottom: _inset,
                        width: tabWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x2EFFFFFF),
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(_inset),
                        child: Row(
                          children: [
                            for (var index = 0; index < items.length; index++)
                              Expanded(
                                child: _TabItem(
                                  item: items[index],
                                  selected: index == currentIndex,
                                  onTap: () {
                                    if (index != currentIndex) {
                                      onChanged(index);
                                    }
                                  },
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 21, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
