#!/usr/bin/env bash
# Memilih Xcode terkunci dan satu iPad yang tersedia, lalu mengekspor UDID ke CI.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
: "${GITHUB_ENV:?Skrip persiapan ini memerlukan GITHUB_ENV dari runner CI.}"

expected_xcode="$(tr -d '[:space:]' < .xcode-version)"
export DEVELOPER_DIR="/Applications/Xcode_${expected_xcode}.app/Contents/Developer"
[[ -d "$DEVELOPER_DIR" ]] || {
  printf 'ci-ipados: Xcode dari .xcode-version tidak tersedia: %s\n' "$DEVELOPER_DIR" >&2
  exit 1
}
actual_xcode="$(xcodebuild -version | sed -n 's/^Xcode //p')"
[[ "$actual_xcode" == "$expected_xcode" ]] || {
  printf 'ci-ipados: perlu Xcode %s, mendapat %s.\n' "$expected_xcode" "$actual_xcode" >&2
  exit 1
}
printf 'DEVELOPER_DIR=%s\n' "$DEVELOPER_DIR" >> "$GITHUB_ENV"
xcodebuild -version

mkdir -p target/ci/ipados
xcrun simctl list --json > target/ci/ipados/simulators.json
sdk_version="$(xcrun --sdk iphonesimulator --show-sdk-version)"
simulator_udid="$(python3 - "$sdk_version" <<'PY'
import json
import re
import sys
from pathlib import Path

def version(value):
    parts = tuple(map(int, value.split(".")))
    return parts + (0,) * (3 - len(parts))

config = Path("apps/ipados/Config/Base.xcconfig").read_text()
match = re.search(r"^IPHONEOS_DEPLOYMENT_TARGET\s*=\s*([0-9.]+)", config, re.M)
if match is None:
    sys.exit("ci-ipados: IPHONEOS_DEPLOYMENT_TARGET tidak ditemukan.")
minimum, maximum = version(match[1]), version(sys.argv[1])
data = json.loads(Path("target/ci/ipados/simulators.json").read_text())
ipad_types = {item["identifier"] for item in data["devicetypes"]
              if item.get("productFamily") == "iPad"}
candidates = []
for runtime in data["runtimes"]:
    runtime_id = runtime["identifier"]
    if not runtime.get("isAvailable") or ".iOS-" not in runtime_id:
        continue
    current = version(runtime["version"])
    if not minimum <= current <= maximum:
        continue
    for device in data["devices"].get(runtime_id, []):
        if device.get("isAvailable") and device.get("deviceTypeIdentifier") in ipad_types:
            candidates.append((current, device["name"], device["udid"], device, runtime))
if not candidates:
    sys.exit("ci-ipados: tidak ada iPad tersedia pada runtime yang didukung Xcode terpilih; periksa inventaris runner.")
# Runtime terbaru dahulu, lalu nama dan UDID untuk urutan yang tetap.
newest = max(item[0] for item in candidates)
selected = min((item for item in candidates if item[0] == newest), key=lambda item: item[1:3])
device, runtime = selected[3:]
Path("target/ci/ipados/selected-simulator.json").write_text(
    json.dumps({"device": device, "runtime": runtime}, indent=2) + "\n")
print(device["udid"])
PY
)"
printf 'ci-ipados: simulator %s\n' "$simulator_udid"
if ! xcrun simctl list devices booted | grep -Fq "$simulator_udid"; then
  xcrun simctl boot "$simulator_udid"
fi
xcrun simctl bootstatus "$simulator_udid" -b
printf 'IPADOS_SIMULATOR_UDID=%s\n' "$simulator_udid" >> "$GITHUB_ENV"
