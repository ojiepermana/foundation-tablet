//! Batas UniFFI antara inti Rust dan aplikasi native.
//!
//! Crate ini hanya memetakan API `tablet-core` ke kontrak UniFFI dan tidak
//! memuat perilaku sendiri. Pustaka yang dihasilkan (`libtablet_ffi.a` dan
//! `libtablet_ffi.so`) dikemas untuk iPad dan Android oleh skrip di `scripts/`.

uniffi::setup_scaffolding!();
