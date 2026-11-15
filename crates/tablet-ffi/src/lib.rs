//! Batas UniFFI antara inti Rust dan aplikasi native.
//!
//! Crate ini hanya memetakan API `tablet-core` ke kontrak UniFFI dan tidak
//! memuat perilaku sendiri. Pustaka yang dihasilkan (`libtablet_ffi.a` dan
//! `libtablet_ffi.so`) dikemas untuk iPad dan Android oleh skrip di `scripts/`.
//! Binding Swift dan Kotlin dihasilkan `scripts/generate-bindings.sh` dari
//! pustaka itu; konvensinya ada di `docs/contracts/ffi-conventions.md`.

uniffi::setup_scaffolding!();

/// Salam untuk `name`, diteruskan apa adanya ke `tablet_core::hello`.
#[uniffi::export]
pub fn hello(name: String) -> String {
    tablet_core::hello(name)
}

#[cfg(test)]
mod tests {
    #[test]
    fn exported_hello_returns_core_greeting() {
        assert_eq!(super::hello("Ayu".to_string()), "Hello, Ayu!");
    }
}
