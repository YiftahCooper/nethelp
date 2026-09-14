# 31: dns-transport. Help is local metadata; sourcing this file runs no checks.
NH_ID=31
NH_NAME='dns-transport'
NH_SUMMARY='The identical DNS question over UDP and TCP.'
NH_WHEN='Suspect UDP-specific loss, filtering or truncation.'
NH_LOOK='RCODE, answers, size and truncation differences between the two transports.'
NH_LIMIT='A small successful response does not prove larger DNSSEC responses can pass.'
nh_run() {
    nh_dns "$NH_RESOLVER" "$NH_DNS_PORT" udp
    nh_dns "$NH_RESOLVER" "$NH_DNS_PORT" tcp
}
