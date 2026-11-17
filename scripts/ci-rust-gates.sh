#!/usr/bin/env bash
# Gerbang yang sama pada setiap runner; rustup membaca rust-toolchain.toml.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

rustup toolchain install
cargo fmt --all --check
cargo clippy --workspace --locked --all-targets -- -D warnings
cargo test --workspace --locked
scripts/test.sh
