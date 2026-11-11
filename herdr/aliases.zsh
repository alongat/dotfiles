# Reinstall every installed herdr integration that is behind the running binary
herdr-update-integrations() {
  command -v herdr >/dev/null || return 0
  local targets=(${(f)"$(herdr integration status 2>/dev/null | awk -F'[: ]' '/: outdated/ {print $1}')"})
  if (( ${#targets} == 0 )); then
    echo "› herdr integrations up to date"
    return 0
  fi
  local t
  for t in $targets; do
    echo "› Updating herdr integration: $t"
    herdr integration install "$t" || echo "  ❌ Failed to update $t"
  done
}
