import SwiftUI
import TabletBindings

@main
struct TabletApp: App {
    var body: some Scene {
        WindowGroup(id: "foundation") {
            FoundationShell()
        }
    }
}

private enum FoundationDestination: String, CaseIterable, Identifiable {
    case greeting
    case foundation

    var id: Self { self }

    var title: String {
        switch self {
        case .greeting: "Salam Rust"
        case .foundation: "Informasi Fondasi"
        }
    }

    var symbol: String {
        switch self {
        case .greeting: "hand.wave"
        case .foundation: "info.circle"
        }
    }
}

private struct FoundationShell: View {
    @Environment(\.openWindow) private var openWindow
    @SceneStorage("navigation.destination") private var storedDestination = FoundationDestination.greeting.rawValue
    @SceneStorage("navigation.compactColumn") private var storedCompactColumn = "detail"
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var name = "Ayu"
    @State private var greeting = ""
    #if DEBUG
    @State private var didResetNavigation = false
    #endif

    private var destination: FoundationDestination {
        FoundationDestination(rawValue: storedDestination) ?? .greeting
    }

    private var selection: Binding<FoundationDestination?> {
        Binding {
            destination
        } set: { value in
            // Native back navigation can clear List selection; retain the last destination.
            guard let value else { return }
            storedDestination = value.rawValue
            storedCompactColumn = "detail"
        }
    }

    private var compactColumn: Binding<NavigationSplitViewColumn> {
        Binding {
            storedCompactColumn == "sidebar" ? .sidebar : .detail
        } set: { value in
            storedCompactColumn = value == .sidebar ? "sidebar" : "detail"
        }
    }

    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: compactColumn
        ) {
            List(FoundationDestination.allCases, selection: selection) { destination in
                NavigationLink(value: destination) {
                    Label(destination.title, systemImage: destination.symbol)
                }
                .accessibilityIdentifier("navigation.\(destination.rawValue)")
            }
            .navigationTitle("Fondasi")
            .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 320)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Jendela Baru", systemImage: "plus.rectangle.on.rectangle") {
                        openWindow(id: "foundation")
                    }
                    .accessibilityIdentifier("navigation.newWindow")
                }
            }
        } detail: {
            Group {
                switch destination {
                case .greeting:
                    GreetingView(name: $name, greeting: $greeting)
                case .foundation:
                    FoundationInformationView()
                }
            }
            .navigationTitle(destination.title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationSplitViewStyle(.balanced)
        #if DEBUG
        .onAppear {
            guard !didResetNavigation else { return }
            didResetNavigation = true
            if ProcessInfo.processInfo.arguments.contains("--fresh-navigation") {
                storedDestination = FoundationDestination.greeting.rawValue
                storedCompactColumn = "detail"
            }
        }
        #endif
    }
}

private struct FoundationInformationView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Informasi Fondasi")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)

                Text("Satu inti Rust, dua antarmuka native.")
                    .foregroundStyle(.secondary)

                information("Perilaku bersama", description: "Rust melalui UniFFI.")
                information("Tampilan iPad", description: "SwiftUI mengatur navigasi dan jendela.")
                information("Batas fondasi", description: "Tanpa modul bisnis, jaringan, atau basis data.")
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .accessibilityIdentifier("foundation.content")
    }

    private func information(_ title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(description)
                .foregroundStyle(.secondary)
        }
    }
}

private struct GreetingView: View {
    @Binding var name: String
    @Binding var greeting: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Salam Rust")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)

                Text("Masukkan nama, lalu tekan Sapa.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Nama")
                    TextField("Nama", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .accessibilityIdentifier("greeting.name")
                        .onSubmit(greet)
                }

                Button("Sapa", action: greet)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("greeting.submit")

                Text(greeting)
                    .font(.title2)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("greeting.result")
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private func greet() {
        greeting = hello(name: name)
    }
}
