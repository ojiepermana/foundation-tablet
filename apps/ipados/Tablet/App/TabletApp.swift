import SwiftUI

/// Titik masuk aplikasi iPad. Fitur 01 hanya menampilkan satu layar statis;
/// salam dari Rust ditambahkan fitur 04.
@main
struct TabletApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Tablet")
        }
    }
}
