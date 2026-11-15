//! Inti Rust aplikasi tablet.
//!
//! Crate ini memegang perilaku dan aturan bersama untuk aplikasi iPad dan
//! Android. Crate ini tidak bergantung pada `uniffi`, kerangka UI, atau API
//! platform. Ekspor ke aplikasi native dilakukan lewat crate `tablet-ffi`.

/// Mengembalikan salam untuk `name`, misalnya `Hello, Ayu!` untuk `Ayu`.
///
/// Fungsi ini total: setiap string, termasuk string kosong, menghasilkan
/// salam. Nama tidak dipangkas atau diubah. Bentuk tanda tangan mengikuti
/// README bagian 6 dan kontraknya ada di spec 0002.
pub fn hello(name: String) -> String {
    format!("Hello, {name}!")
}

#[cfg(test)]
mod tests {
    use super::hello;

    #[test]
    fn greets_ayu() {
        assert_eq!(hello("Ayu".to_string()), "Hello, Ayu!");
    }

    #[test]
    fn greets_bima() {
        assert_eq!(hello("Bima".to_string()), "Hello, Bima!");
    }

    #[test]
    fn empty_name_still_greets() {
        assert_eq!(hello(String::new()), "Hello, !");
    }

    #[test]
    fn keeps_non_ascii_name_unchanged() {
        let name = "Zoë 東京";
        let greeting = hello(name.to_string());
        assert_eq!(greeting, "Hello, Zoë 東京!");
        assert_eq!(
            greeting
                .strip_prefix("Hello, ")
                .and_then(|rest| rest.strip_suffix('!')),
            Some(name)
        );
    }
}
