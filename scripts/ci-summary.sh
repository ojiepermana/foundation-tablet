#!/usr/bin/env bash
# Bukti hasil runner, terpisah dari validasi konfigurasi lokal.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
case "${1:-}" in ipados | android-tablet) target_name="$1" ;; *) exit 2 ;; esac
: "${GITHUB_STEP_SUMMARY:?ci-summary memerlukan GITHUB_STEP_SUMMARY.}"
mkdir -p "target/ci/$target_name"
summary="target/ci/$target_name/result.md"
status() {
  case "$1" in success) printf PASS ;; failure) printf FAIL ;; *) printf NOT_RUN ;; esac
}
{
  printf '## %s\n\n' "$target_name"
  printf 'Tested checkout SHA: `%s`\n\n' "$(git rev-parse HEAD)"
  printf 'Runner: `%s` / `%s`\n\n' "${RUNNER_OS:-unknown}" "${RUNNER_ARCH:-unknown}"
  printf '| Check | Result | Runner outcome |\n| --- | --- | --- |\n'
  for check in GATES PREPARE BUILD ARTIFACTS UI CLEAN; do
    variable="CI_${check}_STATUS"
    outcome="${!variable:-skipped}"
    printf '| %s | %s | %s |\n' "$check" "$(status "$outcome")" "$outcome"
  done
  printf '\nTarget job at reporting time: **%s** (%s).\n' \
    "$(status "${CI_JOB_STATUS:-unknown}")" "${CI_JOB_STATUS:-unknown}"
  printf '\nSkipped/cancelled steps are NOT_RUN. See stage logs and native test reports in the artifact.\n'
  if [[ -f "target/ci/$target_name/ui.log" ]]; then
    printf '\n<details><summary>UI test output (last 80 lines)</summary>\n\n```text\n'
    tail -n 80 "target/ci/$target_name/ui.log"
    printf '\n```\n</details>\n'
  else
    printf '\nUI test output: NOT_RUN; the UI step did not produce a log.\n'
  fi
} | tee "$summary" >> "$GITHUB_STEP_SUMMARY"
