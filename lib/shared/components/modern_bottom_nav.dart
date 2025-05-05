import 'package:flutter/material.dart';
import 'package:weibao/shared/theme/theme_constants.dart';

class ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final Color Function(int)? dynamicBackgroundColor;
  final bool showDivider;
  final Color? dividerColor;

  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.dynamicBackgroundColor,
    this.showDivider = true,
    this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = dynamicBackgroundColor?.call(currentIndex) ?? 
        backgroundColor ?? theme.bottomNavigationBarTheme.backgroundColor ?? AppColors.surface;
    final effectiveSelectedColor =
        selectedItemColor ?? theme.bottomNavigationBarTheme.selectedItemColor ?? AppColors.primaryGreen;
    final effectiveUnselectedColor =
        unselectedItemColor ?? theme.bottomNavigationBarTheme.unselectedItemColor ?? AppColors.textSecondary;
    final effectiveDividerColor = dividerColor ?? theme.dividerColor;

    return SafeArea(
      top: false,
      bottom: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDivider)
            Divider(
              height: 1,
              thickness: 0.5,
              color: effectiveDividerColor,
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: PhysicalModel(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: effectiveBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.black.withOpacity(0.05),
                    width: 0.5,
                  ),),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final isSelected = index == currentIndex;
                      final isPostTab = index == 2;

                      if (isPostTab) {
                        return _buildPostButton(
                          index: index,
                          isSelected: isSelected,
                          selectedColor: effectiveSelectedColor,
                          icon: item.icon,
                        );
                      } else {
                        return _buildNavItem(
                          index: index,
                          isSelected: isSelected,
                          selectedColor: effectiveSelectedColor,
                          unselectedColor: effectiveUnselectedColor,
                          icon: item.icon,
                          activeIcon: item.activeIcon,
                          label: item.label ?? '',
                        );
                      }
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
    required Widget icon,
    Widget? activeIcon,
    required String label,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor.withOpacity(0.1) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: isSelected && activeIcon != null
                          ? activeIcon
                          : IconTheme(
                              data: IconThemeData(
                                color: isSelected ? selectedColor : unselectedColor,
                                size: 24,
                              ),
                              child: icon,
                            ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: -2,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  label,
                  key: ValueKey<bool>(isSelected),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? selectedColor : unselectedColor,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostButton({
    required int index,
    required bool isSelected,
    required Color selectedColor,
    required Widget icon,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: icon,
        ),
      ),
    );
  }
}