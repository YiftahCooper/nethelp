# 30: https-no-dns. Help is local metadata; sourcing this file runs no checks.
NH_ID=30
NH_NAME='https-no-dns'
NH_SUMMARY='Verified HTTPS using a supplied host-to-IP mapping.'
NH_WHEN='Compare with 9 to isolate name resolution from TCP/TLS/HTTP.'
NH_LOOK='Successful HTTPS with --resolve while the normal named request fails.'
NH_LIMIT='A stale/wrong pinned IP can fail despite healthy Internet. Certificates are still verified.'
nh_run() {
    if [ -z "$NH_CONNECT_IP" ]; then nh_note '[provide --connect-ip IP and --url https://HOST/ using a known current mapping]'; return; fi
    authority=${NH_URL#https://}; authority=${authority%%/*}
    case "$authority" in *:*|*@*|'') nh_note '[use an HTTPS hostname URL without credentials or explicit port]'; NH_BROKEN=1; return;; esac
    nh_cmd curl -q --noproxy '*' "-$NH_FAMILY" --connect-timeout 4 --max-time "$NH_TIMEOUT" --resolve "$authority:443:$NH_CONNECT_IP" --silent --show-error --output /dev/null --write-out 'remote_ip=%{remote_ip}\nhttp_code=%{http_code}\ntotal=%{time_total}\n' "$NH_URL"
}
