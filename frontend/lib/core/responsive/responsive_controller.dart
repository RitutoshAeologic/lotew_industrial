import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

enum ScreenLayout { mobile, tablet, desktop }

class ResponsiveController extends GetxController with WidgetsBindingObserver {
  static ResponsiveController get to => Get.find();

  static const double _mobileMax = 767;
  static const double _tabletMax = 1279;

  final screenWidth = 0.0.obs;
  final screenHeight = 0.0.obs;
  final layout = ScreenLayout.desktop.obs;
  final isSidebarExpanded = true.obs;

  bool get isMobile => layout.value == ScreenLayout.mobile;
  bool get isTablet => layout.value == ScreenLayout.tablet;
  bool get isDesktop => layout.value == ScreenLayout.desktop;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _updateLayout();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeMetrics() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), _updateLayout);
  }

  void _updateLayout() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = view.physicalSize / view.devicePixelRatio;

    screenWidth.value = size.width;
    screenHeight.value = size.height;

    final newLayout = switch (size.width) {
      <= _mobileMax => ScreenLayout.mobile,
      <= _tabletMax => ScreenLayout.tablet,
      _ => ScreenLayout.desktop,
    };

    if (layout.value != newLayout) {
      layout.value = newLayout;
      _onLayoutChanged(newLayout);
    }
  }

  void _onLayoutChanged(ScreenLayout newLayout) {
    isSidebarExpanded.value = newLayout == ScreenLayout.desktop;
  }

  void toggleSidebar() {
    isSidebarExpanded.value = !isSidebarExpanded.value;
  }
}

