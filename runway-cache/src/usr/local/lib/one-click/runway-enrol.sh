# Sourced by 001_onboot. Each invocation reuses the controller's pending
# credential so it can recover an exchange whose response was lost.
enrol_runway_cache() {
    local deadline=$((SECONDS + 180)) delay=2 remaining limit status error
    while (( SECONDS < deadline )); do
        remaining=$((deadline - SECONDS))
        limit=$((remaining < 20 ? remaining : 20))
        if error=$(timeout --kill-after=1s "${limit}s" runway-controller \
            --action cache-service-enrol --config "$1" 2>&1); then
            return 0
        else
            status=$?
        fi

        case "$error" in
            'Runway site rejected cache credential')
                echo 'Runway cache enrolment rejected by the site' >&2
                return 1
                ;;
            'Runway cache credential exchange unavailable') ;;
            'Runway cache credential TLS verification failed')
                echo "$error" >&2
                return 1
                ;;
            *)
                if (( status != 124 && status != 137 )); then
                    echo 'Runway cache enrolment failed with a non-retryable error' >&2
                    return 1
                fi
                ;;
        esac

        remaining=$((deadline - SECONDS))
        if (( remaining <= 0 )); then
            break
        fi
        echo 'Runway cache enrolment unavailable, retrying' >&2
        sleep "$((delay < remaining ? delay : remaining))"
        delay=$((delay < 15 ? delay * 2 : 30))
    done
    echo 'Runway cache enrolment remained unavailable for 180 seconds' >&2
    return 1
}
