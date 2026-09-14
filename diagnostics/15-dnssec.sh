# 15: dnssec. Help is local metadata; sourcing this file runs no checks.
NH_ID=15
NH_NAME='dnssec'
NH_SUMMARY='Valid and deliberately bogus signed DNS responses.'
NH_WHEN='Ordinary DNS works, but validation or clock-related failure is suspected.'
NH_LOOK='Valid response versus bogus SERVFAIL, AD flag and a checking-disabled comparison.'
NH_LIMIT='DO requests DNSSEC records; it is not local validation. SERVFAIL alone has many causes.'
nh_run() {
    nh_cmd date -u
    nh_cmd drill "-$NH_FAMILY" -D -p "$NH_DNS_PORT" "@$NH_RESOLVER" cloudflare.com A
    nh_cmd drill "-$NH_FAMILY" -D -p "$NH_DNS_PORT" "@$NH_RESOLVER" dnssec-failed.org A
    nh_cmd drill "-$NH_FAMILY" -D -o CD -p "$NH_DNS_PORT" "@$NH_RESOLVER" dnssec-failed.org A
}
