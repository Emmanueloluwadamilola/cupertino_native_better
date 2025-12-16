import SwiftUI
import UIKit

/// Data model for a single tab item
struct TabBarItem: Identifiable, Equatable {
    let id = UUID()
    let label: String?
    let symbol: String?
    let activeSymbol: String?
    var badge: String?
    let customIconData: Data?
    let activeCustomIconData: Data?
    let imageAssetPath: String?
    let imageAssetData: Data?
    let activeImageAssetPath: String?
    let activeImageAssetData: Data?
    
    // Helper check for equality to avoid unnecessary redraws
    static func == (lhs: TabBarItem, rhs: TabBarItem) -> Bool {
        return lhs.label == rhs.label &&
               lhs.symbol == rhs.symbol &&
               lhs.activeSymbol == rhs.activeSymbol &&
               lhs.badge == rhs.badge &&
               lhs.customIconData == rhs.customIconData &&
               lhs.activeCustomIconData == rhs.activeCustomIconData &&
               lhs.imageAssetPath == rhs.imageAssetPath &&
               lhs.activeImageAssetPath == rhs.activeImageAssetPath
    }
}

/// View Model to hold the state of the Tab Bar
class CupertinoTabBarViewModel: ObservableObject {
    @Published var items: [TabBarItem] = []
    @Published var selectedIndex: Int = 0
    @Published var tint: UIColor?
    @Published var backgroundColor: UIColor?
    @Published var isDark: Bool = false
    @Published var iconScale: CGFloat = 2.0
    
    // Layout
    @Published var split: Bool = false
    @Published var rightCount: Int = 1
    @Published var splitSpacing: CGFloat = 12.0
    
    // Search
    @Published var hasSearch: Bool = false
    @Published var searchPlaceholder: String?
    @Published var searchSymbol: String?
    @Published var searchActiveSymbol: String?
    @Published var automaticallyActivatesSearch: Bool = true
    
    // Search State
    @Published var isSearchActive: Bool = false
    @Published var searchText: String = ""
    
    // Callbacks
    var onIndexChanged: ((Int) -> Void)?
    var onSearchActiveChanged: ((Bool) -> Void)?
    var onSearchTextChanged: ((String) -> Void)?
    var onSearchSubmitted: ((String) -> Void)?
}

@available(iOS 16.0, *)
struct CupertinoTabBarSwiftUI: View {
    @ObservedObject var viewModel: CupertinoTabBarViewModel
    @Namespace private var ns
    
    var body: some View {
        HStack(spacing: 0) {
            if viewModel.split {
                buildSplitLayout()
            } else {
                buildSingleBar()
            }
        }
    }
    
    @ViewBuilder
    private func buildSingleBar() -> some View {
        ZStack {
            Capsule()
                .fill(Color.clear)
                .glassEffect(glassEffectForStyle(interactive: true), in: Capsule())
            
            HStack(spacing: 0) {
                ForEach(Array(viewModel.items.enumerated()), id: \.offset) { index, item in
                    buildTabItem(item, index: index)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 50)
    }
    
    @ViewBuilder
    private func buildSplitLayout() -> some View {
        let totalCount = viewModel.items.count
        let leftCount = max(0, totalCount - viewModel.rightCount)
        let leftItems = Array(viewModel.items.prefix(leftCount))
        
        // Left Bar
        ZStack {
            Capsule()
                .fill(Color.clear)
                .glassEffect(glassEffectForStyle(interactive: true), in: Capsule())
            
            HStack(spacing: 0) {
                ForEach(Array(leftItems.enumerated()), id: \.offset) { index, item in
                    buildTabItem(item, index: index)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 50)
        // If split, left bar can expand, unless we want fixed sizing. 
        // Typically split bars in this design fill available width proportionally or equally.
        // We'll let it flex.
        
        Spacer().frame(width: viewModel.splitSpacing)
        
        // Right Bar (or Search)
        if viewModel.hasSearch {
            buildSearchRightSide()
        } else {
            let rightItems = Array(viewModel.items.suffix(viewModel.rightCount))
            let rightStartIndex = leftCount
            
            ZStack {
                Capsule()
                    .fill(Color.clear)
                    .glassEffect(glassEffectForStyle(interactive: true), in: Capsule())
                
                HStack(spacing: 0) {
                    ForEach(Array(rightItems.enumerated()), id: \.offset) { index, item in
                         buildTabItem(item, index: rightStartIndex + index)
                             .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(height: 50)
            // .frame(width: ...) // Could constrain width if needed
        }
    }
    
    @ViewBuilder
    private func buildSearchRightSide() -> some View {
        if viewModel.isSearchActive {
            // Expanded Search Bar
            ZStack {
                Capsule()
                    .fill(Color(uiColor: .systemBackground).opacity(0.8)) // Or glass
                    .glassEffect(glassEffectForStyle(interactive: false), in: Capsule())
                
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField(viewModel.searchPlaceholder ?? "Search", text: $viewModel.searchText)
                        .submitLabel(.search)
                        .onSubmit {
                            viewModel.onSearchSubmitted?(viewModel.searchText)
                        }
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: { 
                            viewModel.searchText = "" 
                             // notify?
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button("Cancel") {
                        withAnimation {
                            viewModel.isSearchActive = false
                            viewModel.searchText = ""
                            viewModel.onSearchActiveChanged?(false)
                        }
                    }
                    .font(.caption)
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 50)
            .transition(.scale.combined(with: .opacity))
        } else {
            // Search Button
            Button(action: {
                withAnimation {
                    viewModel.isSearchActive = true
                    viewModel.onSearchActiveChanged?(true)
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .glassEffect(glassEffectForStyle(interactive: true), in: Circle())
                    
                    Image(systemName: viewModel.searchSymbol ?? "magnifyingglass")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(viewModel.searchStyleIconColor())
                }
                .frame(width: 50, height: 50)
            }
        }
    }
    
    @ViewBuilder
    private func buildTabItem(_ item: TabBarItem, index: Int) -> some View {
        let isSelected = viewModel.selectedIndex == index
        
        Button(action: {
            if viewModel.selectedIndex != index {
                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.selectedIndex = index
                }
                viewModel.onIndexChanged?(index)
            }
        }) {
            ZStack {
                VStack(spacing: 2) {
                    // Icon
                    if let image = imageFor(item, isSelected: isSelected) {
                         Image(uiImage: image)
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 24)
                    } else if let symbol = (isSelected ? item.activeSymbol : item.symbol) ?? item.symbol {
                         Image(systemName: symbol)
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    // Label
                    if let label = item.label, !label.isEmpty {
                        Text(label)
                            .font(.system(size: 10, weight: .medium))
                    }
                }
                .foregroundColor(isSelected ? (viewModel.tint != nil ? Color(viewModel.tint!) : .blue) : .gray)
                
                // Badge
                if let badge = item.badge, !badge.isEmpty {
                    GeometryReader { geo in
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.red))
                            .position(x: geo.size.width - 8, y: 8)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(SquishableButtonStyle())
    }
    
    private func imageFor(_ item: TabBarItem, isSelected: Bool) -> UIImage? {
        let scale = viewModel.iconScale
        if isSelected {
            if let data = item.activeCustomIconData {
                return UIImage(data: data, scale: scale)?.withRenderingMode(.alwaysTemplate)
            }
            if let path = item.activeImageAssetPath, !path.isEmpty {
                // Determine logic to load from path or data
                 if let data = item.activeImageAssetData {
                    return UIImage(data: data, scale: scale)?.withRenderingMode(.alwaysTemplate)
                 }
                 // In a real app we might load from file system if path provided
            }
        }
        
        if let data = item.customIconData {
            return UIImage(data: data, scale: scale)?.withRenderingMode(.alwaysTemplate)
        }
        if let path = item.imageAssetPath, !path.isEmpty {
             if let data = item.imageAssetData {
                return UIImage(data: data, scale: scale)?.withRenderingMode(.alwaysTemplate)
             }
        }
        
        return nil
    }

    private func glassEffectForStyle(interactive: Bool) -> Glass {
        var glass = Glass.regular
        if let tint = viewModel.backgroundColor {
            glass = glass.tint(Color(tint))
        }
        if interactive {
            glass = glass.interactive()
        }
        return glass
    }
}

// Helper for Search Style
extension CupertinoTabBarViewModel {
    func searchStyleIconColor() -> Color {
        // Return appropriate color from search params or default
        return .secondary
    }
}

// Reuse SquishableButtonStyle from GlassButtonSwiftUI or define here if private
struct SquishableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
