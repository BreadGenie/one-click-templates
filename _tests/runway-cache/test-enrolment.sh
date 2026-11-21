#!/bin/bash
set -euo pipefail

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
cd "$(dirname "$0")"
# shellcheck source=../../runway-cache/src/usr/local/lib/one-click/runway-enrol.sh
. ../../runway-cache/src/usr/local/lib/one-click/runway-enrol.sh
export PATH="$test_dir:$PATH" attempts_file="$test_dir/attempts" scenario
cat > "$test_dir/runway-controller" <<'STUB'
#!/bin/bash
[[ $* == '--action cache-service-enrol --config test.json' ]] || exit 2
echo attempt >> "$attempts_file"
case "$scenario" in
    recovery)
        if [[ $(wc -l < "$attempts_file") -eq 3 ]]; then
            exit 0
        fi
        ;;
    rejected)
        echo 'Runway site rejected cache credential' >&2
        exit 1
        ;;
    permanent)
        echo 'Runway cache credential exchange failed' >&2
        exit 1
        ;;
esac
echo 'Runway cache credential exchange unavailable' >&2
exit 1
STUB
chmod +x "$test_dir/runway-controller"

# Use Bash's elapsed-time variable to advance the clock without delaying tests.
sleep() {
    echo "$1" >> "$test_dir/delays"
    SECONDS=$((SECONDS + $1))
}

for scenario in recovery rejected permanent unavailable; do
    SECONDS=0
    : > "$attempts_file"
    : > "$test_dir/delays"
    if enrol_runway_cache test.json 2>"$test_dir/output"; then
        [[ $scenario == recovery ]]
    else
        [[ $scenario != recovery ]]
    fi
    case "$scenario" in
        recovery)
            [[ $(wc -l < "$attempts_file") -eq 3 ]]
            [[ $(paste -sd ' ' "$test_dir/delays") == '2 4' ]]
            ;;
        rejected|permanent)
            [[ $(wc -l < "$attempts_file") -eq 1 && ! -s $test_dir/delays ]]
            grep -Eq 'rejected|non-retryable' "$test_dir/output"
            ;;
        unavailable)
            [[ $(paste -sd ' ' "$test_dir/delays") == '2 4 8 16 30 30 30 30 30' ]]
            grep -q 'remained unavailable' "$test_dir/output"
            ;;
    esac
done
