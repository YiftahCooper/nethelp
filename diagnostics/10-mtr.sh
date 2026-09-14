# 10: mtr. Help is local metadata; sourcing this file runs no checks.
NH_ID=10
NH_NAME='mtr'
NH_SUMMARY='A finite hop-by-hop path report.'
NH_WHEN='Compare end-to-end loss and latency when connectivity is intermittent or slow.'
NH_LOOK='Loss that continues to the final hop, not an isolated silent intermediate router.'
NH_LIMIT='Intermediate routers often limit ICMP. An asterisk is not proof of a broken hop.'
nh_run() {
    case "$NH_PROTOCOL" in
        tcp) nh_cmd mtr "-$NH_FAMILY" --tcp -P "$NH_PORT" -n -r -c "$NH_COUNT" "$NH_TARGET";;
        udp) nh_cmd mtr "-$NH_FAMILY" --udp -P "$NH_PORT" -n -r -c "$NH_COUNT" "$NH_TARGET";;
        icmp) nh_cmd mtr "-$NH_FAMILY" -n -r -c "$NH_COUNT" "$NH_TARGET";;
    esac
}
