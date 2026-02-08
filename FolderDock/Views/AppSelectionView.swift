import SwiftUI

struct AppSelectionView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    
    var filteredApps: [SystemApp] {
        if searchText.isEmpty {
            return store.systemApps
        } else {
            return store.systemApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack {
            Text("Select Apps")
                .font(.headline)
                .padding(.top)
            
            TextField("Search", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            if store.systemApps.isEmpty {
                ProgressView("Loading Apps...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredApps, id: \.self) { app in
                        HStack {
                            Image(nsImage: app.icon)
                                .resizable()
                                .frame(width: 24, height: 24)
                            Text(app.name)
                            Spacer()
                            if store.isAppSelected(app) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .contentShape(Rectangle()) // Make full row clickable
                        .onTapGesture {
                            store.toggleApp(app)
                        }
                    }
                }
                .listStyle(.inset)
            }
            
            HStack {
                Spacer()
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 400, height: 500)
        .onAppear {
            store.loadSystemApps()
        }
    }
}
