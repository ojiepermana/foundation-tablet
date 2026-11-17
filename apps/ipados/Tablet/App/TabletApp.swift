import SwiftUI
import TabletBindings

@main
struct TabletApp: App {
    var body: some Scene {
        WindowGroup {
            GreetingView()
        }
    }
}

private struct GreetingView: View {
    @State private var name = "Ayu"
    @State private var greeting = ""

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
