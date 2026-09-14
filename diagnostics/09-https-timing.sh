# 9: https-timing. Help is local metadata; sourcing this file runs no checks.
NH_ID=9
NH_NAME='https-timing'
NH_SUMMARY='Verified HTTPS with DNS, TCP, TLS and response timings.'
NH_WHEN='A connection exists but websites fail or are slow.'
NH_LOOK='curl exit/error, remote IP, HTTP status and cumulative timing stages.'
NH_LIMIT='One website is not the entire Internet. Timings are cumulative, not per-stage durations.'
nh_run() {
    nh_cmd curl -q --noproxy '*' "-$NH_FAMILY" --connect-timeout 4 --max-time "$NH_TIMEOUT" --silent --show-error --output /dev/null --write-out 'remote_ip=%{remote_ip}\nhttp_code=%{http_code}\ndns=%{time_namelookup}\nconnect=%{time_connect}\ntls=%{time_appconnect}\nfirst_byte=%{time_starttransfer}\ntotal=%{time_total}\n' "$NH_URL"
}
