import SwiftUI

/// Three-tab root: Calls, Mind Map, Settings. The tab bar is custom-drawn to
/// match the design package's `TabBar` component (warm ivory blur strip with
/// an accent indicator).
struct RootShellView: View {
    @State private var tab: MMTab = .calls
    @State private var callsPath = NavigationPath()
    @State private var mapPath = NavigationPath()
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .calls:
                    // Calls feature uses navigationDestination(item:) to push
                    // CallDetailView; that requires a NavigationStack ancestor.
                    NavigationStack(path: $callsPath) {
                        CallsListView()
                    }
                case .map:
                    NavigationStack(path: $mapPath) {
                        MindMapView()
                    }
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            MurmurTabBar(active: $tab)
                .ignoresSafeArea(edges: .bottom)
        }
        .murmurTheme(scheme == .dark ? .dark : .light)
    }
}

#Preview { RootShellView().environment(\.services, .preview()) }
