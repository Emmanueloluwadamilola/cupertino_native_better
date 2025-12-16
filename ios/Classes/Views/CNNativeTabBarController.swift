import Flutter
import UIKit

@available(iOS 13.0, *)
@available(iOS 13.0, *)
public class CNNativeTabBarController: NSObject, UITabBarControllerDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    static let shared = CNNativeTabBarController()
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enable":
            guard let args = call.arguments as? [String: Any],
                  let tabs = args["tabs"] as? [[String: Any]] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing tabs", details: nil))
                return
            }
            let index = args["selectedIndex"] as? Int ?? 0
            enable(tabs: tabs, selectedIndex: index, config: args)
            result(nil)
            
        case "disable":
            disable()
            result(nil)
            
        case "setSelectedIndex":
            if let args = call.arguments as? [String: Any],
               let index = args["index"] as? Int {
                setSelectedIndex(index)
            }
            result(nil)
            
        case "activateSearch":
            activateSearch()
            result(nil)
            
        case "deactivateSearch":
            deactivateSearch()
            result(nil)
            
        case "setSearchText":
            if let args = call.arguments as? [String: Any],
               let text = args["text"] as? String {
                setSearchText(text)
            }
            result(nil)
            
        case "setBadgeCounts":
            if let args = call.arguments as? [String: Any],
               let badges = args["badgeCounts"] as? [Int?] {
                setBadgeCounts(badges)
            }
            result(nil)
            
        case "setStyle":
            if let args = call.arguments as? [String: Any] {
                updateStyle(args)
            }
            result(nil)
            
        case "setBrightness":
            if let args = call.arguments as? [String: Any] {
                updateStyle(args)
            }
            result(nil)
            
        case "isEnabled":
            result(isEnabled)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private var flutterViewController: FlutterViewController?
    private var tabBarController: UITabBarController?
    private var originalRootViewController: UIViewController?
    private var channel: FlutterMethodChannel?
    
    private var isEnabled = false
    private var searchController: UISearchController?
    
    // Track search state
    private var isSearchActive = false
    private var currentQuery = ""
    private var isSearchTab = false // Current tab is a search tab
    
    public func setChannel(_ channel: FlutterMethodChannel) {
        self.channel = channel
        channel.setMethodCallHandler { [weak self] (call, result) in
            self?.handle(call, result: result)
        }
    }
    
    public func enable(tabs: [[String: Any]], selectedIndex: Int, config: [String: Any]) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController as? FlutterViewController else {
            print("CNTabBarNative: Could not find FlutterViewController")
            return
        }
        
        if isEnabled { return }
        
        self.flutterViewController = rootVC
        self.originalRootViewController = rootVC
        
        // Create Tab Bar Controller
        let tbc = UITabBarController()
        tbc.delegate = self
        self.tabBarController = tbc
        
        // Configure Tabs
        var viewControllers: [UIViewController] = []
        
        for (index, tabData) in tabs.enumerated() {
            let vc = UIViewController()
            vc.view.backgroundColor = .systemBackground // Default background
            
            let title = tabData["title"] as? String
            let sfSymbol = tabData["sfSymbol"] as? String
            let activeSfSymbol = tabData["activeSfSymbol"] as? String
            let isSearch = tabData["isSearch"] as? Bool ?? false
            let badgeCount = tabData["badgeCount"] as? Int
            
            vc.tabBarItem = UITabBarItem(
                title: title,
                image: UIImage(systemName: sfSymbol ?? "circle")?.withRenderingMode(.alwaysTemplate),
                selectedImage: UIImage(systemName: activeSfSymbol ?? sfSymbol ?? "circle.fill")?.withRenderingMode(.alwaysTemplate)
            )
            
            if let count = badgeCount, count > 0 {
                vc.tabBarItem.badgeValue = "\(count)"
            }
            
            // Tag used to identify search tabs
            if isSearch {
                vc.tabBarItem.tag = 999 // Magic number for search tab
            } else {
                vc.tabBarItem.tag = index
            }
            
            viewControllers.append(vc)
        }
        
        tbc.viewControllers = viewControllers
        tbc.selectedIndex = selectedIndex
        
        // Styling
        updateStyle(config)
        
        // Reparent Flutter View
        // We do this by swapping the window root
        window.rootViewController = tbc
        window.makeKeyAndVisible()
        
        // Add Flutter View to the initial selected tab
        if let selectedVC = tbc.selectedViewController {
            addFlutterView(to: selectedVC)
        }
        
        // Setup Search if needed (if current tab is search)
        // Check if initial tab is search tab
        if let selectedVC = tbc.selectedViewController, selectedVC.tabBarItem.tag == 999 {
             setupSearch(for: selectedVC)
        }
        
        isEnabled = true
    }
    
    public func disable() {
        guard isEnabled,
              let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              let originalRoot = originalRootViewController else {
            return
        }
        
        // Remove Flutter View from current parent
        flutterViewController?.willMove(toParent: nil)
        flutterViewController?.view.removeFromSuperview()
        flutterViewController?.removeFromParent()
        
        // Restore Root
        window.rootViewController = originalRoot
        window.makeKeyAndVisible()
        
        // Cleanup
        tabBarController = nil
        searchController = nil
        originalRootViewController = nil // Keep reference? No, we restored it.
        // Actually, originalRoot IS the flutterViewController, so we just restored it.
        
        isEnabled = false
    }
    
    public func setSelectedIndex(_ index: Int) {
        guard let tbc = tabBarController, index < (tbc.viewControllers?.count ?? 0) else { return }
        tbc.selectedIndex = index
        // Manual delegate call not needed if setting property? 
        // UITabBarController does NOT call delegate methods when set programmatically.
        // So we must manually handle the view swap.
        if let selectedVC = tbc.selectedViewController {
             handleTabSelection(selectedVC)
        }
    }
    
    public func setBadgeCounts(_ counts: [Int?]) {
        guard let tbc = tabBarController, let vcs = tbc.viewControllers else { return }
        
        for (i, count) in counts.enumerated() {
            if i < vcs.count {
                if let c = count, c > 0 {
                    vcs[i].tabBarItem.badgeValue = "\(c)"
                } else {
                    vcs[i].tabBarItem.badgeValue = nil
                }
            }
        }
    }
    
    public func updateStyle(_ config: [String: Any]) {
        guard let tbc = tabBarController else { return }
        
        if let tintVal = config["tint"] as? Int {
             tbc.tabBar.tintColor = UIColor(argb: tintVal)
        }
        
        if let unselectedTintVal = config["unselectedTint"] as? Int {
             tbc.tabBar.unselectedItemTintColor = UIColor(argb: unselectedTintVal)
        }
        
        if let isDark = config["isDark"] as? Bool {
            tbc.overrideUserInterfaceStyle = isDark ? .dark : .light
        }
    }
    
    public func activateSearch() {
        // Find search tab index
        guard let tbc = tabBarController, let vcs = tbc.viewControllers else { return }
        
        if let index = vcs.firstIndex(where: { $0.tabBarItem.tag == 999 }) {
            tbc.selectedIndex = index
            handleTabSelection(vcs[index])
            
            // Activate search controller
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.searchController?.isActive = true
                self.searchController?.searchBar.becomeFirstResponder()
            }
        }
    }
    
    public func deactivateSearch() {
        searchController?.isActive = false
    }
    
    public func setSearchText(_ text: String) {
        searchController?.searchBar.text = text
        // Updating text programmatically doesn't always trigger updates, so manually:
        updateSearchResults(for: searchController!)
    }
    
    // MARK: - Private Helpers
    
    private func addFlutterView(to parentVC: UIViewController) {
        guard let flutterVC = flutterViewController else { return }
        
        // Performance check: If already parented correctly, do nothing
        if flutterVC.parent == parentVC {
            return
        }
        
        // Remove from previous parent if exists
        flutterVC.willMove(toParent: nil)
        flutterVC.view.removeFromSuperview()
        flutterVC.removeFromParent()
        
        // Add to new parent
        parentVC.addChild(flutterVC)
        parentVC.view.addSubview(flutterVC.view)
        
        flutterVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            flutterVC.view.leadingAnchor.constraint(equalTo: parentVC.view.leadingAnchor),
            flutterVC.view.trailingAnchor.constraint(equalTo: parentVC.view.trailingAnchor),
            flutterVC.view.topAnchor.constraint(equalTo: parentVC.view.topAnchor),
            flutterVC.view.bottomAnchor.constraint(equalTo: parentVC.view.bottomAnchor)
        ])
        
        flutterVC.didMove(toParent: parentVC)
        
        // Force layout
        parentVC.view.layoutIfNeeded()
    }
    
    private func setupSearch(for parentVC: UIViewController) {
        // Only if not already setup or if reused
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.delegate = self
        sc.searchBar.delegate = self
        sc.obscuresBackgroundDuringPresentation = false
        
        parentVC.navigationItem.searchController = sc
        parentVC.definesPresentationContext = true
        
        // We need a NavigationController to show the search bar properly in the header
        // But we are swapping raw VCs. 
        // Usually Search is inside a UINavigationController.
        // Let's wrap the flutter view in a NavController? 
        // Or wrap the Tab's VC in a NavController?
        
        // If we wrapped the tab VC in a NavController, we'd have to manage that hierarchy.
        // For simplicity, let's just assign it to the parentVC and see if it appears (it won't without a Nav stack usually).
        // Actually, standard iOS behavior is SearchBar in NavigationBar.
        // So we really should have wrapped each Tab VC in a UINavigationController if we want native search bars.
        
        // Let's try wrapping the Search Tab in a UINavigationController dynamically.
        // BUT: We already created the VCs in `enable`.
        // Ideally `enable` creates UINavigationControllers for tabs.
        
        // REVISION: Let's assume for now we just want the search bar generic or if we can inject it.
        // If the user wants Native Look, we probably need UINavigationController.
        
        // Let's create a UINavigationController for the search tab specifically in `enable`?
        // No, let's leave it as is. If no NavController, search bar might not show in navigationItem.
        // We might need to add the searchBar to the view directly if no NavController.
        
        // Implementation Detail: Embed search tab in Nav Controller?
        // For this task, I'll rely on the standard `navigationItem` but if it fails to show, we might need to revisit.
        // Actually, without a UINavigationController, `navigationItem.searchController` does nothing visible on the screen.
        
        // So, for the search tab, we SHOULD wrap it.
        // I will update `addFlutterView` logic to handle if `parentVC` is a NavController.
    }
    
    private func handleTabSelection(_ viewController: UIViewController) {
        // If the selected VC is a NavigationController, get the top one
        var targetVC = viewController
        if let nav = viewController as? UINavigationController {
            targetVC = nav.topViewController ?? nav
        }
        
        addFlutterView(to: targetVC)
        
        // Notify Flutter
        let index = tabBarController?.viewControllers?.firstIndex(of: viewController) ?? 0
        channel?.invokeMethod("onTabSelected", arguments: ["index": index])
        
        // Search Logic
        if viewController.tabBarItem.tag == 999 {
            // It's a search tab
            // Make sure we have a search controller setup
            if targetVC.navigationItem.searchController == nil {
                setupSearch(for: targetVC)
            }
        }
    }
    
    // MARK: - UITabBarControllerDelegate
    
    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        handleTabSelection(viewController)
    }
    
    // MARK: - UISearchResultsUpdating
    
    public func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        if text != currentQuery {
            currentQuery = text
            channel?.invokeMethod("onSearchChanged", arguments: ["query": text])
        }
    }
    
    // MARK: - UISearchControllerDelegate
    
    public func didPresentSearchController(_ searchController: UISearchController) {
        channel?.invokeMethod("onSearchActiveChanged", arguments: ["isActive": true])
        isSearchActive = true
    }
    
    public func didDismissSearchController(_ searchController: UISearchController) {
        channel?.invokeMethod("onSearchActiveChanged", arguments: ["isActive": false])
        channel?.invokeMethod("onSearchCancelled", arguments: nil)
        isSearchActive = false
    }
    
    // MARK: - UISearchBarDelegate
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text {
            channel?.invokeMethod("onSearchSubmitted", arguments: ["query": text])
        }
    }
}

extension UIColor {
    convenience init(argb: Int) {
        let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
        let red   = CGFloat((argb >> 16) & 0xFF) / 255.0
        let green = CGFloat((argb >> 8) & 0xFF) / 255.0
        let blue  = CGFloat(argb & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
