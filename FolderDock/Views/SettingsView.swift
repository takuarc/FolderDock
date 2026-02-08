import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAppSelector = false // NEW State
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Settings").font(.headline)
            Divider()
            
            // CHANGED: Open Sheet instead of NSOpenPanel
            Button("Manage Apps...") {
                showAppSelector = true
            }
            .sheet(isPresented: $showAppSelector) {
                AppSelectionView()
                    .environmentObject(store)
            }
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Icon Size")
                Slider(
                    value: $store.iconSize,
                    in: 32...128,
                    onEditingChanged: { editing in
                        if !editing { store.saveSettings() }
                    }
                )
            }
            Divider()
            
            Toggle("Use List View", isOn: $store.isListView)
                .toggleStyle(.switch)
                .onChange(of: store.isListView) {
                    store.saveSettings()
                }
            
            HStack {
                Spacer()
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding()
        .frame(width: 250)
    }
}
