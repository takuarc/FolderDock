import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAppSelector = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Settings").font(.headline)
            Divider()
            
            Button("Manage Apps...") {
                showAppSelector = true
            }
            .sheet(isPresented: $showAppSelector) {
                AppSelectionView().environmentObject(store)
            }
            
            Divider()
            
            // Theme Picker
            VStack(alignment: .leading) {
                Text("Theme")
                Picker("", selection: $store.theme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                // FIX: Modern onChange syntax (0 params)
                .onChange(of: store.theme) {
                    store.saveSettings()
                }
            }
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Icon Size: \(Int(store.iconSize))px")
                Slider(
                    value: $store.iconSize,
                    in: 32...128,
                    onEditingChanged: { editing in
                        if !editing { store.saveSettings() }
                    }
                )
            }
            
            VStack(alignment: .leading) {
                Text("Text Size: \(Int(store.textSize))pt")
                Slider(
                    value: $store.textSize,
                    in: 8...24,
                    onEditingChanged: { editing in
                        if !editing { store.saveSettings() }
                    }
                )
            }
            
            Divider()
            
            Toggle("Use List View", isOn: $store.isListView)
                .toggleStyle(.switch)
                // FIX: Modern onChange syntax (0 params)
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
