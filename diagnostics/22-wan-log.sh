# 22: wan-log. Help is local metadata; sourcing this file runs no checks.
NH_ID=22
NH_NAME='wan-log'
NH_SUMMARY='Retained WAN, driver, DHCP and PPP events.'
NH_WHEN='Locate link flaps, USB resets, lease failures and reconnects.'
NH_LOOK='Event timing and named devices; compare with the actual outage time.'
NH_LIMIT='Retained logs may cover only the current boot and may have wrapped.'
nh_run() {
    nh_wan
    nh_log_match logread "netifd|udhcpc|odhcp6c|pppd|r8152|bcmgenet|xhci|carrier|${NH_PHY:-WAN}"
    nh_log_match dmesg "r8152|bcmgenet|xhci|carrier|NETDEV|${NH_PHY:-WAN}"
}
