#!/bin/bash
set -euo pipefail
umask 022

# Cargo copies the public build inputs before running this script.
if [[ -f /etc/one-click/runway-release.env ]]; then
    # shellcheck disable=SC1091
    . /etc/one-click/runway-release.env
fi
: "${RUNWAY_RELEASE_URL:?Set the pinned cache release URL}"
: "${RUNWAY_RELEASE_SHA256:?Set the pinned cache release SHA-256}"
[[ $RUNWAY_RELEASE_URL == https://* && $RUNWAY_RELEASE_SHA256 =~ ^[a-f0-9]{64}$ ]]
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
    --retry 3 --max-time 120 "$RUNWAY_RELEASE_URL" -o "$work/release.tar.gz"
printf '%s  %s\n' "$RUNWAY_RELEASE_SHA256" "$work/release.tar.gz" | sha256sum --check --status
tar --extract --gzip --file "$work/release.tar.gz" --directory "$work" --no-same-owner --no-same-permissions \
    runway-cache/bin/runway-controller \
    runway-cache/systemd/runway-cache-service.service \
    runway-cache/systemd/runway-cache-data.service
install -D -m 0755 "$work/runway-cache/bin/runway-controller" /usr/local/bin/runway-controller
for unit in runway-cache-service.service runway-cache-data.service; do
    install -D -m 0644 "$work/runway-cache/systemd/$unit" "/etc/systemd/system/$unit"
done
rm -f /etc/one-click/runway-release.env
