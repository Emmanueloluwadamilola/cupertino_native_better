import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
import '../utils/version_detector.dart';
import '../style/sf_symbol.dart';

/// Data model for a native tab
class CNTab {
  const CNTab({
    this.title,
    this.sfSymbol,
    this.activeSfSymbol,
    this.isSearchTab = false,
    this.badgeCount,
  });

  /// Tab title
  final String? title;

  /// SF Symbol for unselected state
  final CNSymbol? sfSymbol;

  /// SF Symbol for selected state
  final CNSymbol? activeSfSymbol;

  /// Whether this is a search tab (iOS 26+ only)
  final bool isSearchTab;

  /// Badge count (null to hide)
  final int? badgeCount;
}

class CNTabBarNative {
  static const MethodChannel _channel = MethodChannel('cn_native_tab_bar');

  static bool _isEnabled = false;
  static void Function(int index)? _onTabSelected;
  static void Function(String query)? _onSearchChanged;
  static void Function(String query)? _onSearchSubmitted;
  static VoidCallback? _onSearchCancelled;
  static void Function(bool isActive)? _onSearchActiveChanged;

  /// Enable native tab bar mode
  ///
  /// This will replace your app's root view controller with a native
  /// UITabBarController. Your Flutter content will be displayed within
  /// the selected tab.
  ///
  /// Only works on iOS 26+. On older versions, this is a no-op.
  static Future<void> enable({
    required List<CNTab> tabs,
    int selectedIndex = 0,
    void Function(int index)? onTabSelected,
    void Function(String query)? onSearchChanged,
    void Function(String query)? onSearchSubmitted,
    VoidCallback? onSearchCancelled,
    void Function(bool isActive)? onSearchActiveChanged,
    Color? tintColor,
    Color? unselectedTintColor,
    bool? isDark,
  }) async {
    // Only works on iOS 26+
    if (defaultTargetPlatform != TargetPlatform.iOS ||
        !PlatformVersion.shouldUseNativeGlass) {
      return;
    }

    if (_isEnabled &&
        _onTabSelected == onTabSelected &&
        _onSearchChanged == onSearchChanged) {
      // Already enabled with same callbacks? Maybe update tabs?
      // For now, let's allow re-enabling to update config
    }

    // Store callbacks
    _onTabSelected = onTabSelected;
    _onSearchChanged = onSearchChanged;
    _onSearchSubmitted = onSearchSubmitted;
    _onSearchCancelled = onSearchCancelled;
    _onSearchActiveChanged = onSearchActiveChanged;

    // Setup method call handler for callbacks
    _channel.setMethodCallHandler(_handleMethodCall);

    try {
      // Enable native tab bar
      await _channel.invokeMethod('enable', {
        'tabs': tabs
            .map(
              (tab) => {
                'title': tab.title,
                'sfSymbol': tab.sfSymbol?.name,
                'activeSfSymbol': tab.activeSfSymbol?.name,
                'isSearch': tab.isSearchTab,
                'badgeCount': tab.badgeCount,
              },
            )
            .toList(),
        'selectedIndex': selectedIndex,
        'isDark': isDark ?? false,
        if (tintColor != null) 'tint': tintColor.value,
        if (unselectedTintColor != null)
          'unselectedTint': unselectedTintColor.value,
      });

      _isEnabled = true;
    } catch (e) {
      debugPrint('Error enabling CNTabBarNative: $e');
      _isEnabled = false;
    }
  }

  /// Disable native tab bar and return to Flutter-only mode
  static Future<void> disable() async {
    if (!_isEnabled) {
      return;
    }

    try {
      await _channel.invokeMethod('disable');
    } catch (e) {
      debugPrint('Error disabling CNTabBarNative: $e');
    } finally {
      _channel.setMethodCallHandler(null);
      _isEnabled = false;
      _onTabSelected = null;
      _onSearchChanged = null;
      _onSearchSubmitted = null;
      _onSearchCancelled = null;
      _onSearchActiveChanged = null;
    }
  }

  /// Set the selected tab index
  static Future<void> setSelectedIndex(int index) async {
    if (!_isEnabled) return;
    await _channel.invokeMethod('setSelectedIndex', {'index': index});
  }

  /// Activate the search (go to search tab and focus search bar)
  static Future<void> activateSearch() async {
    if (!_isEnabled) return;
    await _channel.invokeMethod('activateSearch');
  }

  /// Deactivate the search
  static Future<void> deactivateSearch() async {
    if (!_isEnabled) return;
    await _channel.invokeMethod('deactivateSearch');
  }

  /// Set the search text programmatically
  static Future<void> setSearchText(String text) async {
    if (!_isEnabled) return;
    await _channel.invokeMethod('setSearchText', {'text': text});
  }

  /// Update badge counts for tabs
  static Future<void> setBadgeCounts(List<int?> badgeCounts) async {
    if (!_isEnabled) return;
    await _channel.invokeMethod('setBadgeCounts', {'badgeCounts': badgeCounts});
  }

  /// Update style (tint colors)
  static Future<void> setStyle({
    Color? tintColor,
    Color? unselectedTintColor,
  }) async {
    if (!_isEnabled) return;
    await _channel.invokeMethod('setStyle', {
      if (tintColor != null) 'tint': tintColor.value,
      if (unselectedTintColor != null)
        'unselectedTint': unselectedTintColor.value,
    });
  }

  /// Update brightness (dark mode)
  static Future<void> setBrightness({required bool isDark}) async {
    if (!_isEnabled) return;
    await _channel.invokeMethod('setBrightness', {'isDark': isDark});
  }

  /// Check if native tab bar is currently enabled
  static Future<bool> checkIsEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Whether the native tab bar is enabled
  static bool get isEnabled => _isEnabled;

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onTabSelected':
        final index = call.arguments['index'] as int;
        _onTabSelected?.call(index);
        break;
      case 'onSearchChanged':
        final query = call.arguments['query'] as String;
        _onSearchChanged?.call(query);
        break;
      case 'onSearchSubmitted':
        final query = call.arguments['query'] as String;
        _onSearchSubmitted?.call(query);
        break;
      case 'onSearchCancelled':
        _onSearchCancelled?.call();
        break;
      case 'onSearchActiveChanged':
        final isActive = call.arguments['isActive'] as bool;
        _onSearchActiveChanged?.call(isActive);
        break;
      case 'onTabAppeared':
        // Tab appeared - could be used for analytics
        break;
    }
  }
}

/// A Widget wrapper for CNTabBarNative
///
/// Use this in your `Scaffold`'s `bottomNavigationBar` slot (or anywhere in the tree,
/// though it doesn't render visible Flutter content itself).
///
/// It handles enabling the native tab bar on `initState` and disabling it on `dispose`.
class CNNativeTabBar extends StatefulWidget {
  const CNNativeTabBar({
    super.key,
    required this.tabs,
    required this.currentTab,
    required this.onTabChanged,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onSearchCancelled,
    this.onSearchActiveChanged,
    this.tintColor,
    this.unselectedTintColor,
    this.isDark,
  });

  /// The tabs to display
  final List<CNTab> tabs;

  /// The currently selected tab index
  final int currentTab;

  /// Callback when a tab is selected
  final ValueChanged<int> onTabChanged;

  /// Callback when search text changes (search tab only)
  final ValueChanged<String>? onSearchChanged;

  /// Callback when search is submitted (search tab only)
  final ValueChanged<String>? onSearchSubmitted;

  /// Callback when search is cancelled
  final VoidCallback? onSearchCancelled;

  /// Callback when search active state changes
  final ValueChanged<bool>? onSearchActiveChanged;

  /// Tint color for selected items
  final Color? tintColor;

  /// Tint color for unselected items
  final Color? unselectedTintColor;

  /// Whether to force dark mode (null for system)
  final bool? isDark;

  @override
  State<CNNativeTabBar> createState() => _CNNativeTabBarState();
}

class _CNNativeTabBarState extends State<CNNativeTabBar> {
  @override
  void initState() {
    super.initState();
    _enable();
  }

  @override
  void didUpdateWidget(covariant CNNativeTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTab != widget.currentTab) {
      CNTabBarNative.setSelectedIndex(widget.currentTab);
    }

    // Check for style or tab changes
    if (oldWidget.tintColor != widget.tintColor ||
        oldWidget.unselectedTintColor != widget.unselectedTintColor) {
      CNTabBarNative.setStyle(
        tintColor: widget.tintColor,
        unselectedTintColor: widget.unselectedTintColor,
      );
    }

    // Note: If tabs list changes dynamically, we need a method to update tabs without full re-enable
    // For now, we assume tabs don't change often, or we re-enable if they do.
    // If you need dynamic tabs, we implement 'updateTabs' in CNTabBarNative.
    // For this implementation, we re-call enable if tabs count/content changes.
    // A simple equality check or just re-enabling if key props change is safest for now.
    if (!_tabsEqual(oldWidget.tabs, widget.tabs) ||
        oldWidget.isDark != widget.isDark) {
      _enable();
    }
  }

  bool _tabsEqual(List<CNTab> a, List<CNTab> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].title != b[i].title ||
          a[i].sfSymbol?.name != b[i].sfSymbol?.name ||
          a[i].badgeCount != b[i].badgeCount)
        return false;
    }
    return true;
  }

  Future<void> _enable() async {
    await CNTabBarNative.enable(
      tabs: widget.tabs,
      selectedIndex: widget.currentTab,
      onTabSelected: widget.onTabChanged,
      onSearchChanged: widget.onSearchChanged,
      onSearchSubmitted: widget.onSearchSubmitted,
      onSearchCancelled: widget.onSearchCancelled,
      onSearchActiveChanged: widget.onSearchActiveChanged,
      tintColor: widget.tintColor,
      unselectedTintColor: widget.unselectedTintColor,
      isDark: widget.isDark,
    );
  }

  @override
  void dispose() {
    CNTabBarNative.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The native tab bar replaces the root view controller, so we don't need to render anything here.
    // However, if we are in a Scaffold, bottomNavigationBar expects a widget.
    // SizedBox.shrink() works but might have 0 height.
    // If the Scaffold bodies are relying on bottom padding, this might be an issue.
    // Since the native tab bar is taking over the screen, the Flutter view is now INSIDE the tab.
    // So the Scaffold inside the Flutter view should probably NOT have a bottomNavigationBar
    // or it should be hidden/transparent if we use this widget declaratively.

    // Actually, if using this widget, it should ideally be placed at the top level of the app
    // or used as a side-effect controller.
    // Putting it in 'bottomNavigationBar' slot of a scaffold that is *inside* the tab
    // would be recursive logic (Native Tab -> Flutter VC -> Scaffold -> BottomNav -> THIS).
    // That's fine, as long as we return 0 size.
    return const SizedBox.shrink();
  }
}
