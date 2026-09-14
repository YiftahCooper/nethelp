# 13: adguard-query. Help is local metadata; sourcing this file runs no checks.
NH_ID=13
NH_NAME='adguard-query'
NH_SUMMARY='A question to the configured primary DNS resolver.'
NH_WHEN='Check the normal local DNS service, whether AdGuardHome or another resolver.'
NH_LOOK='Answer, RCODE, flags and elapsed time; blocked domains can intentionally return zero addresses.'
NH_LIMIT='A cached answer does not prove upstream DNS works now.'
nh_run() {
    nh_dns "$NH_RESOLVER" "$NH_DNS_PORT"
}
