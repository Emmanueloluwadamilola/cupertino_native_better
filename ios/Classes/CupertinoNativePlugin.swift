import Flutter
import UIKit

public class CupertinoNativePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cupertino_native", binaryMessenger: registrar.messenger())
    let instance = CupertinoNativePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Register platform view factories
    let sliderFactory = CupertinoSliderViewFactory(messenger: registrar.messenger())
    registrar.register(sliderFactory, withId: "CupertinoNativeSlider")

    let switchFactory = CupertinoSwitchViewFactory(messenger: registrar.messenger())
    registrar.register(switchFactory, withId: "CupertinoNativeSwitch")

    // Segmented control
    let segmentedFactory = CupertinoSegmentedControlViewFactory(messenger: registrar.messenger())
    registrar.register(segmentedFactory, withId: "CupertinoNativeSegmentedControl")

    let iconFactory = CupertinoIconViewFactory(messenger: registrar.messenger())
    registrar.register(iconFactory, withId: "CupertinoNativeIcon")

    let tabBarFactory = CupertinoTabBarViewFactory(messenger: registrar.messenger())
    registrar.register(tabBarFactory, withId: "CupertinoNativeTabBar")

    let popupMenuFactory = CupertinoPopupMenuButtonViewFactory(messenger: registrar.messenger())
    registrar.register(popupMenuFactory, withId: "CupertinoNativePopupMenuButton")

    let buttonFactory = CupertinoButtonViewFactory(messenger: registrar.messenger())
    registrar.register(buttonFactory, withId: "CupertinoNativeButton")
    
    let glassButtonGroupFactory = CupertinoGlassButtonGroupFactory(messenger: registrar.messenger())
    registrar.register(glassButtonGroupFactory, withId: "CupertinoNativeGlassButtonGroup")
    
    let liquidGlassContainerFactory = LiquidGlassContainerFactory(messenger: registrar.messenger())
    registrar.register(liquidGlassContainerFactory, withId: "CupertinoNativeLiquidGlassContainer")

    // Search bar
    let searchBarFactory = CupertinoSearchBarFactory(messenger: registrar.messenger())
    registrar.register(searchBarFactory, withId: "CNSearchBar")

    // Navigation Bar
    let navigationBarFactory = CupertinoNavigationBarFactory(messenger: registrar.messenger())
    registrar.register(navigationBarFactory, withId: "CupertinoNativeNavigationBar")

    // Floating island (Dynamic Island style)
    let floatingIslandFactory = FloatingIslandFactory(messenger: registrar.messenger())
    registrar.register(floatingIslandFactory, withId: "CNFloatingIsland")
    
    // Native Tab Bar Controller Channel
    let nativeTabBarChannel = FlutterMethodChannel(name: "cn_native_tab_bar", binaryMessenger: registrar.messenger())
    let nativeTabBarController = CNNativeTabBarController.shared
    nativeTabBarController.setChannel(nativeTabBarChannel)
    registrar.addMethodCallDelegate(nativeTabBarController, channel: nativeTabBarChannel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "getMajorOSVersion":
      let version = ProcessInfo.processInfo.operatingSystemVersion
      result(Int(version.majorVersion))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
 
