import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @State private var showSettings = false
    @State private var showAppSelector = false

    @State private var draggedApp: AppItem?

    var body: some View {
        VStack(spacing: 0) {
            header

            if store.apps.isEmpty {
                emptyState
            } else {
                if store.isListView {
                    listView
                } else {
                    gridView
                }
            }
        }
        .frame(minWidth: 300, minHeight: 200)
        // Background drag surface:
        // - enabled in normal mode so user can drag the popup around
        // - disabled in edit mode so icon drag/reorder is stable
        .background(WindowDragSurface(enabled: !store.isEditMode))
    }

    private var header: some View {
        HStack {
            Button {
                store.isEditMode.toggle()
            } label: {
                Text(store.isEditMode ? "Done" : "Edit")
                    .font(.caption)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(store.isEditMode ? Color.accentColor : Color.clear)
                    .foregroundColor(store.isEditMode ? .white : .primary)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSettings) {
                SettingsView().environmentObject(store)
            }
        }
        .padding(10)
        .background(store.isEditMode ? Color.accentColor.opacity(0.10) : Color.clear)
    }

    private var emptyState: some View {
        VStack {
            Button { showAppSelector = true } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
            }
            .buttonStyle(.plain)

            Text("Add Apps")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showAppSelector) {
            AppSelectionView().environmentObject(store)
        }
    }

    private var listView: some View {
        List {
            ForEach(store.apps) { app in
                HStack {
                    Image(nsImage: app.icon)
                        .resizable()
                        .frame(width: 32, height: 32)

                    Text(app.name)
                        .font(.headline)

                    Spacer()

                    if store.isEditMode {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    if !store.isEditMode { store.launch(app) }
                }
                .contextMenu {
                    Button("Remove") { store.removeApp(id: app.id) }
                }
                .moveDisabled(!store.isEditMode)
            }
            .onMove(perform: store.moveApp)
        }
        .listStyle(.plain)
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: store.iconSize, maximum: 120), spacing: 15)],
                spacing: 15
            ) {
                ForEach(store.apps) { app in
                    VStack {
                        ZStack(alignment: .topTrailing) {
                            Image(nsImage: app.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: store.iconSize, height: store.iconSize)

                            if store.isEditMode {
                                Button {
                                    store.removeApp(id: app.id)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Circle().fill(Color.white))
                                }
                                .buttonStyle(.plain)
                                .offset(x: 6, y: -6)
                            }
                        }

                        Text(app.name)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .frame(width: store.iconSize + 20)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !store.isEditMode { store.launch(app) }
                    }
                    .onDrag {
                        guard store.isEditMode else { return NSItemProvider() }
                        draggedApp = app
                        return NSItemProvider(object: app.id.uuidString as NSString)
                    }
                    .onDrop(
                        of: [UTType.text],
                        delegate: AppDropDelegate(
                            isEnabled: store.isEditMode,
                            item: app,
                            apps: $store.apps,
                            draggedItem: $draggedApp,
                            store: store
                        )
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - AppKit window drag surface
struct WindowDragSurface: NSViewRepresentable {
    var enabled: Bool

    func makeNSView(context: Context) -> DragView {
        let v = DragView()
        v.enabled = enabled
        v.wantsLayer = true
        v.layer?.backgroundColor = .clear
        return v
    }

    func updateNSView(_ nsView: DragView, context: Context) {
        nsView.enabled = enabled
    }

    final class DragView: NSView {
        var enabled: Bool = true

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func mouseDown(with event: NSEvent) {
            guard enabled, let window else { return }
            // FIX: Correct API name is performDrag(with:)
            window.performDrag(with: event)
        }
    }
}

// MARK: - Grid drop delegate
struct AppDropDelegate: DropDelegate {
    let isEnabled: Bool
    let item: AppItem
    @Binding var apps: [AppItem]
    @Binding var draggedItem: AppItem?
    let store: AppStore

    func dropEntered(info: DropInfo) {
        guard isEnabled, let draggedItem else { return }
        guard item != draggedItem else { return }

        guard
            let from = apps.firstIndex(of: draggedItem),
            let to = apps.firstIndex(of: item)
        else { return }

        withAnimation(.default) {
            apps.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        guard isEnabled else { return false }
        store.saveApps()
        draggedItem = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        isEnabled ? DropProposal(operation: .move) : DropProposal(operation: .cancel)
    }
}
