# Shared execution and selection. Diagnostic recipes live in diagnostics/.
nh_error() { printf 'nethelp: %s\n' "$*" >&2; }
nh_note() { printf '%s\n' "$*"; }
nh_defaults() {
    NH_HELP=0 NH_PLAN=0 NH_PARALLEL=0 NH_INTERACTIVE=0 NH_ITEMS=
    NH_WAN=wan NH_INTERFACE= NH_PHYSICAL= NH_TARGET=1.1.1.1 NH_FAMILY=4
    NH_RESOLVER=127.0.0.1 NH_DNS_PORT=53 NH_SECONDARY= NH_SECONDARY_PORT=54
    NH_DOMAIN=example.com NH_TYPE=A NH_COUNT=3 NH_INTERVAL=5 NH_SECONDS=30
    NH_TIMEOUT=10 NH_PORT=443 NH_URL=https://example.com/ NH_CONNECT_IP=
    NH_TLS_ENDPOINT=1.1.1.1:853 NH_TLS_NAME=cloudflare-dns.com NH_CLIENT=
    NH_OUTPUT= NH_ENTRIES=0 NH_CONFIG= NH_CONFIG_EXPLICIT=0 NH_PROTOCOL=icmp
    NH_TARGET_SET=0 NH_RESOLVER_SET=0
}
nh_value() {
    key=$1 value=$2
    case "$value" in ''|*[!a-zA-Z0-9_./:@%+=,-]*|-*) nh_error "Invalid value for $key"; return 2;; esac
    case "$key" in
        wan) NH_WAN=$value;; interface) NH_INTERFACE=$value;; physical) NH_PHYSICAL=$value;;
        target) NH_TARGET=$value; NH_TARGET_SET=1;; family) NH_FAMILY=$value;;
        resolver) NH_RESOLVER=$value; NH_RESOLVER_SET=1;; dns-port) NH_DNS_PORT=$value;;
        protocol) NH_PROTOCOL=$value;;
        secondary) NH_SECONDARY=$value;; secondary-port) NH_SECONDARY_PORT=$value;;
        domain) NH_DOMAIN=$value;; type) NH_TYPE=$value;;
        count) NH_COUNT=$value;; interval) NH_INTERVAL=$value;; seconds) NH_SECONDS=$value;;
        timeout) NH_TIMEOUT=$value;; port) NH_PORT=$value;; url) NH_URL=$value;;
        connect-ip) NH_CONNECT_IP=$value;; tls-endpoint) NH_TLS_ENDPOINT=$value;;
        tls-name) NH_TLS_NAME=$value;; client) NH_CLIENT=$value;;
        *) nh_error "Unknown configuration key: $key"; return 2;;
    esac
}
nh_load_config() {
    [ -n "$NH_CONFIG" ] || NH_CONFIG=/etc/nethelp.conf
    if [ ! -f "$NH_CONFIG" ]; then
        [ "$NH_CONFIG_EXPLICIT" = 0 ] && return 0
        nh_error "Configuration not found: $NH_CONFIG"; return 2
    fi
    while IFS= read -r line || [ -n "$line" ]; do
        line=$(printf '%s' "$line" | tr -d '\r')
        case "$line" in ''|\#*) continue;; *=*) ;; *) nh_error 'Expected key=value in configuration'; return 2;; esac
        nh_value "${line%%=*}" "${line#*=}" || return 2
    done < "$NH_CONFIG"
}
nh_range() {
    case "$2" in ''|*[!0-9]*) nh_error "$1 must be numeric"; return 2;; esac
    [ "${#2}" -le 5 ] && [ "$2" -ge "$3" ] && [ "$2" -le "$4" ] && return 0
    nh_error "$1 must be $3..$4"; return 2
}
nh_validate_options() {
    case "$NH_FAMILY" in 4|6) ;; *) nh_error 'family must be 4 or 6'; return 2;; esac
    if [ "$NH_FAMILY" = 6 ]; then
        [ "$NH_TARGET_SET" = 1 ] || NH_TARGET=2606:4700:4700::1111
        [ "$NH_RESOLVER_SET" = 1 ] || NH_RESOLVER=::1
    fi
    case "$NH_PROTOCOL" in icmp|tcp|udp) ;; *) nh_error 'protocol must be icmp, tcp or udp'; return 2;; esac
    nh_range count "$NH_COUNT" 1 20 && nh_range interval "$NH_INTERVAL" 1 60 &&
    nh_range seconds "$NH_SECONDS" 1 300 && nh_range timeout "$NH_TIMEOUT" 1 60 &&
    nh_range port "$NH_PORT" 1 65535 && nh_range dns-port "$NH_DNS_PORT" 1 65535 &&
    nh_range secondary-port "$NH_SECONDARY_PORT" 1 65535 || return 2
    case "$NH_URL" in https://*) ;; *) nh_error 'url must use https://'; return 2;; esac
    authority=${NH_URL#https://}; authority=${authority%%/*}
    case "$authority" in *@*) nh_error 'Credential-bearing URLs are not supported'; return 2;; esac
    case "$NH_INTERFACE$NH_PHYSICAL$NH_WAN" in *[!a-zA-Z0-9_.:-]*) nh_error 'Invalid interface name'; return 2;; esac
}
nh_find() {
    for f in "$NH_ROOT"/diagnostics/*.sh; do
        . "$f"
        if [ "$1" = "$NH_ID" ] || [ "$1" = "$NH_NAME" ]; then printf '%s\n' "$f"; return 0; fi
    done
    return 1
}
nh_select() {
    NH_SELECTED=
    set -f
    set -- $(printf '%s\n' "$*" | tr ',' ' ')
    set +f
    for token do
        f=$(nh_find "$token") || { nh_error "Unknown diagnostic: $token (use nethelp help)"; return 2; }
        . "$f"
        case " $NH_SELECTED " in *" $NH_ID "*) ;; *) NH_SELECTED="$NH_SELECTED $NH_ID";; esac
    done
    [ -n "$NH_SELECTED" ] || { nh_error 'No diagnostics selected'; return 2; }
}
nh_menu() {
    printf 'Nethelp %s - Read-only outage diagnostics\nUsage: nethelp [options] ITEM [ITEM ...]\n\n' "$NH_VERSION"
    for f in "$NH_ROOT"/diagnostics/*.sh; do . "$f"; printf '%2s %-20s %s\n' "$NH_ID" "$NH_NAME" "$NH_SUMMARY"; done
    printf '\nhelp 7 / -h 7 / 7 -h: explain without running\n1 2 or 1,2: run several; --parallel: at most two at once\n--commands: show recipes without executing; menu: show this list; q: quit\nOptions: --wan NAME --interface DEV --physical DEV --family 4|6\n  --target HOST --count 1..20 --timeout 1..60 --interval 1..60 --seconds 1..300\n  --resolver IP --dns-port PORT --secondary IP --secondary-port PORT\n  --domain NAME --type TYPE --port PORT --url https://HOST/PATH\n  --connect-ip IP --tls-endpoint HOST:PORT --tls-name NAME --client IP\n  --entries --output FILE --config FILE --interactive\nFull guide: README.md alongside this release. No -why option.\n'
}
nh_help_item() {
    . "$(nh_find "$1")"
    printf '\n%s %s\nWhat it checks: %s\nWhen to use: %s\nLook for: %s\nDoes not prove: %s\n' "$NH_ID" "$NH_NAME" "$NH_SUMMARY" "$NH_WHEN" "$NH_LOOK" "$NH_LIMIT"
}
nh_quote() {
    case "$1" in
        *"'"*) printf "'"; printf '%s' "$1" | sed "s/'/'\\\\''/g"; printf "'";;
        *) printf "'%s'" "$1";;
    esac
}
nh_print_command() {
    printf '$ '; nh_quote "${NETHELP_TIMEOUT_BIN:-timeout}"; printf ' -k 2s %ss' "$NH_TIMEOUT"
    for arg in "$@"; do printf ' '; nh_quote "$arg"; done
    printf '\n'
}
nh_filter() {
    awk '
      /-----BEGIN .*PRIVATE KEY-----/ {key=1; print "[private key removed]"; next}
      key {if (/-----END .*PRIVATE KEY-----/) key=0; next}
      { low=tolower($0) }
      low ~ /(password|passwd|passphrase|psk|authorization|cookie|token|api.key|private.key|secret)[[:space:]_":=]/ {
        print "[credential-bearing line removed]"; next
      }
      {print}
    ' | sed -E 's#(https?://)[^ /:@]+:[^ /@]+@#\1[credentials]@#g'
}
nh_cancel() {
    trap '' INT TERM HUP
    [ -z "$NH_CHILD" ] || { kill -TERM "$NH_CHILD" 2>/dev/null; wait "$NH_CHILD" 2>/dev/null; }
    nh_note '[cancelled; any saved report is partial]'
    exit 130
}
nh_cmd() {
    if [ -n "$NH_DEADLINE" ] && [ "$NH_PLAN" = 0 ]; then
        read -r elapsed ignored < /proc/uptime
        remaining=$((NH_DEADLINE - ${elapsed%%.*}))
        [ "$remaining" -gt 0 ] || { nh_note '[observation window ended]'; return 124; }
        [ "$remaining" -ge "$NH_TIMEOUT" ] || NH_TIMEOUT=$remaining
    fi
    nh_print_command "$@"
    [ "$NH_PLAN" = 0 ] || return 0
    if ! command -v "$1" >/dev/null 2>&1; then
        nh_note "[command unavailable: $1]"; NH_BROKEN=1; return 127
    fi
    "${NETHELP_TIMEOUT_BIN:-timeout}" -k 2s "${NH_TIMEOUT}s" "$@" > "$NH_TMP/command" 2>&1 < /dev/null &
    NH_CHILD=$!
    wait "$NH_CHILD"; NH_RC=$?
    NH_CHILD=
    nh_filter < "$NH_TMP/command"
    if [ "$NH_RC" -ne 0 ]; then
        printf '[command exit=%s' "$NH_RC"
        case "$NH_RC" in 124|137) printf '; time limit reached'; NH_BROKEN=1;; 126|127) NH_BROKEN=1;; esac
        case "$1" in ping|drill|nslookup|nc|curl|openssl|mtr|tracepath|pidof) ;; *) NH_BROKEN=1;; esac
        printf ']\n'
    fi
    return "$NH_RC"
}
nh_capture() {
    nh_cmd "$@"; NH_CAPTURE_RC=$?
    if [ "$NH_PLAN" = 0 ] && [ "$NH_CAPTURE_RC" = 0 ]; then NH_DATA=$(cat "$NH_TMP/command"); else NH_DATA=; fi
    return "$NH_CAPTURE_RC"
}
nh_optional() {
    if [ "$NH_PLAN" = 1 ] || command -v "$1" >/dev/null 2>&1; then nh_cmd "$@"; else nh_note "[optional command unavailable: $1]"; fi
}
nh_wan() {
    if [ "$NH_PLAN" = 1 ]; then
        nh_cmd ubus call "network.interface.$NH_WAN" status
        NH_DEV=${NH_INTERFACE:-'<discovered-l3-device>'}
        NH_PHY=${NH_PHYSICAL:-'<discovered-physical-device>'}
        return 0
    fi
    NH_DEV=$NH_INTERFACE NH_PHY=$NH_PHYSICAL
    nh_capture ubus call "network.interface.$NH_WAN" status
    if [ "$NH_CAPTURE_RC" = 0 ]; then
        printf '%s\n' "$NH_DATA" > "$NH_TMP/wan.json"
        if [ -z "$NH_DEV" ]; then
            nh_capture jsonfilter -i "$NH_TMP/wan.json" -e '@.l3_device'
            NH_DEV=$NH_DATA
        fi
        if [ -z "$NH_PHY" ]; then
            nh_capture jsonfilter -i "$NH_TMP/wan.json" -e '@.device'
            NH_PHY=$NH_DATA
        fi
    fi
    [ -n "$NH_PHY" ] || NH_PHY=$NH_DEV
    case "$NH_DEV$NH_PHY" in *[!a-zA-Z0-9_.:-]*) nh_note '[ambiguous or invalid WAN devices; use explicit overrides]'; return 1;; esac
    [ -n "$NH_DEV" ] || { nh_note '[no usable WAN L3 device found; set --wan or --interface]'; return 1; }
    printf 'logical_wan=%s l3_device=%s physical_device=%s\n' "$NH_WAN" "$NH_DEV" "$NH_PHY"
    [ -z "$NH_INTERFACE" ] || nh_note 'L3 device source: explicit override'
}
nh_ping() {
    if [ -n "$NH_INTERFACE" ]; then nh_cmd ping "-$NH_FAMILY" -n -I "$NH_INTERFACE" -c "$NH_COUNT" -W 2 "$1"
    else nh_cmd ping "-$NH_FAMILY" -n -c "$NH_COUNT" -W 2 "$1"; fi
}
nh_dns() {
    server=$1 port=$2 transport=${3:-udp} domain=${4:-$NH_DOMAIN}
    printf 'resolver=%s port=%s transport=%s question=%s %s\n' "$server" "$port" "$transport" "$domain" "$NH_TYPE"
    if [ "$NH_PLAN" = 1 ] || command -v drill >/dev/null 2>&1; then
        if [ "$transport" = tcp ]; then nh_cmd drill -t "-$NH_FAMILY" -p "$port" "@$server" "$domain" "$NH_TYPE"
        else nh_cmd drill "-$NH_FAMILY" -p "$port" "@$server" "$domain" "$NH_TYPE"; fi
    elif [ "$port" = 53 ] && [ "$transport" = udp ]; then
        nh_note 'Fallback: nslookup; record type/flags/transport control may be limited.'
        nh_cmd nslookup "$domain" "$server"
    else nh_note '[drill required for this DNS port/transport]'; NH_BROKEN=1; fi
}
nh_log_match() {
    source=$1 pattern=$2
    nh_print_command "$source"
    [ "$NH_PLAN" = 0 ] || { nh_note "Filter retained output using extended regex: $pattern"; return; }
    if ! command -v "$source" >/dev/null 2>&1; then nh_note "[command unavailable: $source]"; NH_BROKEN=1; return; fi
    "${NETHELP_TIMEOUT_BIN:-timeout}" -k 2s "${NH_TIMEOUT}s" "$source" > "$NH_TMP/log" 2>&1 < /dev/null &
    NH_CHILD=$!; wait "$NH_CHILD"; rc=$?; NH_CHILD=
    if [ "$rc" != 0 ]; then nh_filter < "$NH_TMP/log"; nh_note "[log read failed: exit=$rc; history unknown]"; NH_BROKEN=1; return; fi
    printf '$ grep -Ei '; nh_quote "$pattern"; printf ' < retained-log\n'
    grep -Ei "$pattern" "$NH_TMP/log" > "$NH_TMP/matches"; rc=$?
    case "$rc" in
        0) nh_filter < "$NH_TMP/matches";;
        1) nh_note 'No matching event found in the retained log; this does not prove it never happened.';;
        *) nh_note "[log filter failed: exit=$rc]"; NH_BROKEN=1;;
    esac
}
nh_execute() (
    . "$(nh_find "$1")"
    printf '\n=== %s %s ===\n' "$NH_ID" "$NH_NAME"
    NH_BROKEN=0 NH_CHILD= NH_DEV= NH_PHY= NH_DEADLINE=
    if [ "$NH_PLAN" = 0 ]; then
        NH_TMP=$(mktemp -d "${TMPDIR:-/tmp}/nethelp.XXXXXX") || exit 3
        trap 'rm -rf "$NH_TMP"' EXIT
        trap nh_cancel INT TERM HUP
    fi
    nh_run
    [ "$NH_PLAN" = 1 ] || printf 'collection=%s (network outcomes are in command output)\n' "$(if [ "$NH_BROKEN" = 0 ]; then printf complete; else printf incomplete; fi)"
    [ "$NH_BROKEN" = 0 ] || exit 3
)
nh_batch() {
    result=0
    if [ "$NH_PARALLEL" = 1 ]; then
        case " $NH_SELECTED " in *" 21 "*|*" 26 "*|*" 32 "*) nh_note 'Sampling/report selection: using sequential execution.'; NH_PARALLEL=0;; esac
    fi
    if [ "$NH_PARALLEL" = 0 ] || [ "$NH_PLAN" = 1 ]; then
        for id in $NH_SELECTED; do
            nh_execute "$id" &
            worker=$!
            trap 'kill -TERM "$worker" 2>/dev/null; wait "$worker" 2>/dev/null; exit 130' INT TERM HUP
            wait "$worker"; worker_result=$?
            trap - INT TERM HUP
            [ "$worker_result" != 130 ] || return 130
            [ "$worker_result" = 0 ] || result=3
        done
    else
        batchdir=$(mktemp -d "${TMPDIR:-/tmp}/nethelp-batch.XXXXXX") || return 3
        pids= ids=
        trap 'for p in $pids; do kill -TERM "$p" 2>/dev/null; done; for p in $pids; do wait "$p" 2>/dev/null; done; rm -rf "$batchdir"; exit 130' INT TERM HUP
        for id in $NH_SELECTED; do
            nh_execute "$id" > "$batchdir/$id" 2>&1 &
            pids="$pids $!" ids="$ids $id"
            set -- $pids
            if [ "$#" = 2 ]; then
                for p in $pids; do wait "$p" || result=3; done
                for n in $ids; do cat "$batchdir/$n"; done
                pids= ids=
            fi
        done
        for p in $pids; do wait "$p" || result=3; done
        for n in $ids; do cat "$batchdir/$n"; done
        rm -rf "$batchdir"; trap - INT TERM HUP
    fi
    return "$result"
}
nh_sample_counters() {
    dev=$1 destination=$2
    : > "$destination"
    nh_capture date +%s; printf 'time %s\n' "$NH_DATA" >> "$destination"
    nh_capture cat /proc/sys/kernel/random/boot_id; printf 'boot %s\n' "$NH_DATA" >> "$destination"
    nh_capture cat "/sys/class/net/$dev/ifindex"; printf 'ifindex %s\n' "$NH_DATA" >> "$destination"
    for metric in rx_bytes tx_bytes rx_packets tx_packets rx_errors tx_errors rx_dropped tx_dropped; do
        nh_capture cat "/sys/class/net/$dev/statistics/$metric"
        case "$NH_DATA" in ''|*[!0-9]*) nh_note "[invalid sample: $metric]"; NH_BROKEN=1; return 1;; esac
        printf '%s %s\n' "$metric" "$NH_DATA" >> "$destination"
    done
}
nh_report() {
    NH_PARALLEL=0
    if [ -z "$NH_OUTPUT" ]; then
        reportdir=$(mktemp -d "${TMPDIR:-/tmp}/nethelp-report.XXXXXX") || return 3
        NH_OUTPUT="$reportdir/report.txt"
    fi
    if [ -e "$NH_OUTPUT" ] || [ -L "$NH_OUTPUT" ]; then nh_error 'Report already exists; choose a new path'; return 2; fi
    partial="$NH_OUTPUT.partial"
    (set -C; : > "$partial") 2>/dev/null || { nh_error 'Cannot create a new partial report'; return 3; }
    printf 'Collecting selected checks into %s ...\n' "$partial"
    {
        printf 'Nethelp %s\n' "$NH_VERSION"
        if [ "$NH_PLAN" = 1 ]; then printf 'mode=command-preview\n'; else printf 'mode=diagnostic-collection\n'; fi
        printf 'selected=%s\n' "$NH_SELECTED"
        date -u
        nh_batch
        report_result=$?
        printf '\nreport_collection_exit=%s\n' "$report_result"
    } >> "$partial"
    write_result=$?
    [ "$write_result" = 0 ] || { nh_error "Report write failed; partial evidence: $partial"; return 3; }
    # Hard-link promotion is atomic and refuses to replace an existing name.
    ln "$partial" "$NH_OUTPUT" 2>/dev/null || { nh_error "Report promotion failed; partial evidence: $partial"; return 3; }
    rm "$partial"
    cat "$NH_OUTPUT" || return 3
    printf '\nreport=%s\n' "$NH_OUTPUT"
    sha256sum "$NH_OUTPUT"
    return "$report_result"
}
nh_dispatch() (
    if [ "$NH_HELP" = 1 ]; then
        if [ -z "$NH_ITEMS" ]; then nh_menu; return; fi
        nh_select "$NH_ITEMS" || return 2
        for id in $NH_SELECTED; do nh_help_item "$id"; done
        return
    fi
    nh_select "$NH_ITEMS" || return 2
    [ "$NH_SELECTED" != ' 27' ] || NH_PLAN=1
    case " $NH_SELECTED " in
        *" 26 "*)
            NH_SELECTED=$(printf '%s\n' "$NH_SELECTED" | sed 's/ 26\( \|$\)/ /')
            [ -n "$(printf '%s' "$NH_SELECTED" | tr -d ' ')" ] || NH_SELECTED='1 2 3 4 5 6 7 8 12 13 20 22 23 25 28 29'
            NH_REPORT=1;;
        *) NH_REPORT=0;;
    esac
    if [ "$NH_PLAN" = 1 ] && [ -z "$NH_OUTPUT" ]; then NH_REPORT=0; fi
    if [ "$NH_PLAN" = 0 ] && ! command -v "${NETHELP_TIMEOUT_BIN:-timeout}" >/dev/null 2>&1; then
        nh_error 'timeout is required for execution; help and --commands still work'; return 3
    fi
    if [ "$NH_PLAN" = 0 ]; then
        printf '$ '; nh_quote "${NETHELP_TIMEOUT_BIN:-timeout}"; printf ' --version\n'
        timeout_version=$("${NETHELP_TIMEOUT_BIN:-timeout}" --version 2>&1)
        case "$timeout_version" in *'GNU coreutils'*) ;; *) nh_error 'GNU coreutils timeout is required; other timeout exit semantics are not supported'; return 3;; esac
        printf '%s\n' "$timeout_version" | sed -n '1p'
    fi
    if [ "$NH_REPORT" = 1 ] || [ -n "$NH_OUTPUT" ]; then nh_report; else nh_batch; fi
)
nh_main() {
    umask 077
    nh_defaults
    for arg in "$@"; do case "$arg" in help|-h|--help) NH_HELP=1;; esac; done
    prev=
    for arg in "$@"; do
        [ "$prev" != --config ] || { NH_CONFIG=$arg; NH_CONFIG_EXPLICIT=1; }
        prev=$arg
    done
    [ "$NH_HELP" = 1 ] || nh_load_config || return 2
    while [ "$#" -gt 0 ]; do
        case "$1" in
            help|-h|--help) NH_HELP=1;;
            --commands) NH_PLAN=1;; --parallel) NH_PARALLEL=1;;
            --interactive) NH_INTERACTIVE=1;; --entries) NH_ENTRIES=1;;
            --config|--output)
                opt=$1; shift; [ "$#" -gt 0 ] || { nh_error "Missing value: $opt"; return 2; }
                [ "$opt" != --output ] || NH_OUTPUT=$1;;
            --wan|--interface|--physical|--target|--family|--resolver|--dns-port|--secondary|--secondary-port|--domain|--type|--count|--interval|--seconds|--timeout|--port|--url|--connect-ip|--tls-endpoint|--tls-name|--client|--protocol)
                opt=${1#--}; shift; [ "$#" -gt 0 ] || { nh_error "Missing value: $opt"; return 2; }
                nh_value "$opt" "$1" || return 2;;
            --*) nh_error "Unknown option: $1"; return 2;;
            *) NH_ITEMS="$NH_ITEMS $1";;
        esac
        shift
    done
    nh_validate_options || return 2
    if [ -n "$NH_ITEMS" ] || [ "$NH_HELP" = 1 ]; then nh_dispatch; return; fi
    nh_menu
    if [ "$NH_INTERACTIVE" = 1 ] || [ -t 0 ]; then
        while printf '\nNext checks (numbers/names), help ITEM, menu, or q: '; IFS= read -r choice; do
            case "$choice" in q|quit|exit|0) break;; menu|help|-h|--help) nh_menu; continue;; '') continue;; esac
            NH_HELP=0
            case "$choice" in 'help '*) NH_HELP=1; choice=${choice#help };; '-h '*) NH_HELP=1; choice=${choice#-h };; *' -h') NH_HELP=1; choice=${choice% -h};; esac
            NH_ITEMS=$choice
            nh_dispatch
        done
    fi
    return 0
}
