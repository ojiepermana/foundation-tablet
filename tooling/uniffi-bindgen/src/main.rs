//! Generator binding UniFFI untuk repo ini (Tooling, lapisan E).
//!
//! Biner ini memakai versi `uniffi` yang sama dengan runtime lewat pin
//! workspace, sehingga tidak perlu `cargo install`. Hanya
//! `scripts/generate-bindings.sh` yang memanggilnya. Build mobile tidak
//! memakai crate ini; pustaka mobile selalu dibangun dengan `-p tablet-ffi`.

fn main() {
    uniffi::uniffi_bindgen_main()
}
