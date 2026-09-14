# 14: dnsmasq-query. Help is local metadata; sourcing this file runs no checks.
NH_ID=14
NH_NAME='dnsmasq-query'
NH_SUMMARY='The same question to an explicitly selected secondary resolver.'
NH_WHEN='Compare AdGuardHome with dnsmasq or another local backend.'
NH_LOOK='Whether the backend answers the same question on its actual address and port.'
NH_LIMIT='An unconfigured secondary service is not an Internet failure.'
nh_run() {
    if [ -z "$NH_SECONDARY" ]; then
      nh_note '[secondary resolver not configured; use --secondary IP --secondary-port PORT]'
      return
    fi
    nh_dns "$NH_SECONDARY" "$NH_SECONDARY_PORT"
}
