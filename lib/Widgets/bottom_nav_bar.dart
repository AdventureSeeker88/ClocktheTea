import 'package:flutter/material.dart';
import '../Const/AppColors.dart';

/// Professional bottom navigation with 4 tabs:
/// Home | Search | Tea | Profile
/// - Use by placing inside a Scaffold bottomNavigationBar or as a persistent widget
class AppBottomNavBar extends StatefulWidget {
  /// Provide an optional initial index (default 0)
  final int initialIndex;

  /// Callback when item is tapped
  final ValueChanged<int>? onTabSelected;

  const AppBottomNavBar({
    super.key,
    this.initialIndex = 0,
    this.onTabSelected,
  });

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _handleTap(int index) {
    if (_selectedIndex == index) {
      // optionally handle double-tap (scroll to top etc.)
    }
    setState(() => _selectedIndex = index);
    widget.onTabSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    // Sizes adapt to device width for better visual balance
    final double barHeight = 72;
    final double cornerRadius = 20;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Material(
          // Elevated rounded container
          color: Colors.transparent,
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(cornerRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: AppColors.deepPurple.withOpacity(0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_filled,
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.search,
                  label: 'Search',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.local_cafe, // Tea icon
                  label: 'Tea',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_outline,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _selectedIndex == index;

    // Selected styles
    final Color selectedIconColor = AppColors.deepPurple;
    final Color selectedLabelColor = AppColors.deepPurple;
    final Color activeBg = AppColors.gold.withOpacity(0.15); // subtle pill
    final Color unselectedColor = AppColors.textSecondary;

    return Expanded(
      child: Semantics(
        container: true,
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          onTap: () => _handleTap(index),
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.teal.withOpacity(0.14),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // ✅ centers items
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected ? activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? selectedIconColor : unselectedColor,
                  semanticLabel: label,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? selectedLabelColor : unselectedColor,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.only(top: 2),
                width: isSelected ? 20 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
