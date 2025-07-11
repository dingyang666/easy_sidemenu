import 'package:easy_sidemenu/src/side_menu_display_mode.dart';
import 'package:easy_sidemenu/src/side_menu_hamburger_mode.dart';
import 'package:easy_sidemenu/src/side_menu_item.dart';
import 'package:easy_sidemenu/src/side_menu_style.dart';
import 'package:easy_sidemenu/src/side_menu_toggle.dart';
import 'package:easy_sidemenu/src/side_menu_item_with_global.dart';
import 'package:easy_sidemenu/src/models/side_menu_item_type.dart';
import 'package:easy_sidemenu/src/side_menu_expansion_item.dart';
import 'package:easy_sidemenu/src/side_menu_expansion_item_with_global.dart';
import 'package:easy_sidemenu/src/side_menu_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'global/global.dart';

class SideMenu extends StatefulWidget {
  /// Page controller to control [PageView] widget
  final SideMenuController controller;

  /// List of [SideMenuItem] or [SideMenuExpansionItem] on [SideMenu]
  final List<SideMenuItemType> items;

  /// Title widget will shows on top of all items,
  /// it can be a logo or a Title text
  final Widget? title;

  /// Footer widget will show on bottom of [SideMenu]
  /// when [displayMode] was SideMenuDisplayMode.open
  final Widget? footer;

  /// [SideMenu] can be configured by this
  final SideMenuStyle? style;

  /// Show toggle button to switch between open and compact display mode
  /// If the display mode is auto, this button will not be displayed
  final bool? showToggle;

  /// By default footer only shown when display mode is open
  /// If you want always shown footer set it to true
  final bool? alwaysShowFooter;

  /// Notify when [SideMenuDisplayMode] changed
  final ValueChanged<SideMenuDisplayMode>? onDisplayModeChanged;

  /// Duration of [displayMode] toggling duration
  final Duration? displayModeToggleDuration;

  /// Width when will our open menu collapse into the compact one
  final int? collapseWidth;

  /// ### Easy Sidemenu widget
  ///
  /// Sidemenu is a menu that is usually located
  /// on the left or right of the page and can used for navigation
  const SideMenu({
    Key? key,
    required this.items,
    required this.controller,
    this.title,
    this.footer,
    this.style,
    this.showToggle = false,
    this.onDisplayModeChanged,
    this.displayModeToggleDuration,
    this.alwaysShowFooter = false,
    this.collapseWidth = 600,
  }) : super(key: key);

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  double _currentWidth = 0;
  late bool showToggle;
  late bool alwaysShowFooter;
  late int collapseWidth;
  bool animationInProgress = false;
  SideMenuHamburgerMode _hamburgerMode = SideMenuHamburgerMode.open;

  late final Global global;
  final SideMenuItemList sidemenuitems = SideMenuItemList();

  @override
  void initState() {
    super.initState();
    global = Global();
    _initializeSideMenu();

    showToggle = widget.showToggle ?? false;
    alwaysShowFooter = widget.alwaysShowFooter ?? false;
    collapseWidth = widget.collapseWidth ?? 600;
    global.displayModeState.addListener(_displayModeChangeListener);
  }

  void _initializeSideMenu() {
    global.style = widget.style ?? SideMenuStyle();
    global.controller = widget.controller;

    int sideMenuExpansionItemCount = 0;
    for (int index = 0; index < widget.items.length; index++) {
      if (widget.items[index] is SideMenuExpansionItem) {
        sideMenuExpansionItemCount++;
      }
    }

    if (global.expansionStateList.length != sideMenuExpansionItemCount) {
      global.expansionStateList =
          List<bool>.filled(sideMenuExpansionItemCount, false);

      int expansionItemIndex = -1;
      for (final item in widget.items) {
        if (item is SideMenuExpansionItem) {
          expansionItemIndex++;
          if (item.initialExpanded == true) {
            global.expansionStateList[expansionItemIndex] = true;
          }
        }
      }
    }

    int sideMenuExpansionItemIndex = -1;
    sidemenuitems.items = widget.items.map((data) {
      if (data is SideMenuItem) {
        return SideMenuItemWithGlobal(
          global: global,
          title: data.title,
          onTap: data.onTap,
          icon: data.icon,
          iconWidget: data.iconWidget,
          badgeContent: data.badgeContent,
          badgeColor: data.badgeColor,
          tooltipContent: data.tooltipContent,
          trailing: data.trailing,
          builder: data.builder,
        );
      } else {
        data = data as SideMenuExpansionItem;
        sideMenuExpansionItemIndex = sideMenuExpansionItemIndex + 1;
        return SideMenuExpansionItemWithGlobal(
          global: global,
          title: data.title,
          icon: data.icon,
          index: sideMenuExpansionItemIndex,
          iconWidget: data.iconWidget,
          onTap: data.onTap,
          children: data.children
              .map((childData) => SideMenuItemWithGlobal(
                    global: global,
                    title: childData.title,
                    onTap: childData.onTap,
                    icon: childData.icon,
                    iconWidget: childData.iconWidget,
                    badgeContent: childData.badgeContent,
                    badgeColor: childData.badgeColor,
                    tooltipContent: childData.tooltipContent,
                    trailing: childData.trailing,
                    builder: childData.builder,
                  ))
              .toList(),
        );
      }
    }).toList();
    global.items = sidemenuitems.items;
  }

  void _displayModeChangeListener() {
    _updateWidth();
  }

  void _updateWidth() {
    final newWidth = _calculateWidth(global.displayModeState.value, context);
    if (mounted && newWidth != _currentWidth) {
      setState(() {
        _currentWidth = newWidth;
      });
    }
  }

  @override
  void didUpdateWidget(covariant SideMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    showToggle = widget.showToggle ?? false;
    alwaysShowFooter = widget.alwaysShowFooter ?? false;
    collapseWidth = widget.collapseWidth ?? 600;

    if (widget.controller != oldWidget.controller ||
        widget.items != oldWidget.items) {
      _initializeSideMenu();
    }
    if (widget.style != oldWidget.style) {
      global.style = widget.style ?? SideMenuStyle();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentWidth = _calculateWidth(global.displayModeState.value, context);
  }

  void _toggleHamburgerState() {
    if (_hamburgerMode == SideMenuHamburgerMode.close) {
      setState(() {
        _hamburgerMode = SideMenuHamburgerMode.open;
      });
    } else {
      setState(() {
        _hamburgerMode = SideMenuHamburgerMode.close;
      });
    }
  }

  void _notifyParent() {
    if (widget.onDisplayModeChanged != null) {
      widget.onDisplayModeChanged!(global.displayModeState.value);
    }
  }

  double _calculateWidth(SideMenuDisplayMode mode, BuildContext context) {
    double width = global.style.openSideMenuWidth ?? 300;

    if (mode == SideMenuDisplayMode.auto) {
      width = _calculateAutoWidth(context);
    } else if (mode == SideMenuDisplayMode.open) {
      width = _calculateOpenWidth();
    } else if (mode == SideMenuDisplayMode.compact) {
      width = _calculateCompactWidth();
    }

    return width;
  }

  double _calculateAutoWidth(BuildContext context) {
    if (MediaQuery.of(context).size.width > collapseWidth) {
      return _calculateOpenWidth();
    } else {
      return _calculateCompactWidth();
    }
  }

  double _calculateOpenWidth() {
    global.displayModeState.change(SideMenuDisplayMode.open);
    _notifyParent();
    Future.delayed(_toggleDuration(), () {
      if (mounted) {
        global.showTrailing = true;
      }
    });
    return global.style.openSideMenuWidth ?? 300;
  }

  double _calculateCompactWidth() {
    global.displayModeState.change(SideMenuDisplayMode.compact);
    _notifyParent();
    global.showTrailing = false;
    return global.style.compactSideMenuWidth ?? 50;
  }

  Decoration _decoration(SideMenuStyle? menuStyle) {
    if (menuStyle == null || menuStyle.decoration == null) {
      return BoxDecoration(
        color: global.style.backgroundColor,
      );
    } else {
      if (menuStyle.backgroundColor != null) {
        menuStyle.decoration =
            menuStyle.decoration!.copyWith(color: menuStyle.backgroundColor);
      }
      return menuStyle.decoration!;
    }
  }

  Duration _toggleDuration() {
    return widget.displayModeToggleDuration ??
        const Duration(milliseconds: 350);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: global,
      child: Builder(builder: (context) {
        final IconButton hamburgerIcon = IconButton(
          icon: const Icon(IconData(0xe3dc, fontFamily: 'MaterialIcons')),
          onPressed: _toggleHamburgerState,
        );

        return ((global.style.showHamburger) &&
                (_hamburgerMode == SideMenuHamburgerMode.close))
            ? Align(alignment: Alignment.topLeft, child: hamburgerIcon)
            : AnimatedContainer(
                duration: _toggleDuration(),
                width: this._currentWidth,
                height: MediaQuery.sizeOf(context).height,
                decoration: _decoration(widget.style),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (global.style.showHamburger) hamburgerIcon,
                          if (global.style.displayMode ==
                                  SideMenuDisplayMode.compact &&
                              showToggle)
                            const SizedBox(
                              height: 42,
                            ),
                          if (widget.title != null) widget.title!,
                          ...sidemenuitems.items,
                        ],
                      ),
                    ),
                    if ((widget.footer != null &&
                            global.displayModeState.value !=
                                SideMenuDisplayMode.compact) ||
                        (widget.footer != null && alwaysShowFooter))
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: widget.footer!,
                      ),
                    if (global.style.displayMode != SideMenuDisplayMode.auto &&
                        showToggle)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: global.displayModeState.value ==
                                  SideMenuDisplayMode.open
                              ? 0
                              : 4,
                          vertical: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SideMenuToggle(
                              global: global,
                              onTap: () {
                                if (context
                                        .findAncestorStateOfType<
                                            _SideMenuState>()
                                        ?.animationInProgress ??
                                    false) {
                                  return;
                                }
                                if (global.displayModeState.value ==
                                    SideMenuDisplayMode.compact) {
                                  setState(() {
                                    global.style.displayMode =
                                        SideMenuDisplayMode.open;
                                  });
                                } else if (global.displayModeState.value ==
                                    SideMenuDisplayMode.open) {
                                  setState(() {
                                    global.style.displayMode =
                                        SideMenuDisplayMode.compact;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
      }),
    );
  }

  @override
  void dispose() {
    global.displayModeState.removeListener(_displayModeChangeListener);
    global.dispose();
    super.dispose();
  }
}
