# 29: wan-status. Help is local metadata; sourcing this file runs no checks.
NH_ID=29
NH_NAME='wan-status'
NH_SUMMARY='WAN protocol, acquisition state, addresses, routes and advertised DNS.'
NH_WHEN='A link is up but there is no usable Internet connection.'
NH_LOOK='up/pending/errors, DHCP or PPP state, L3 device, routes, DNS and available lease timing.'
NH_LIMIT='Obtaining a DHCP lease does not prove ISP forwarding or DNS works.'
nh_run() {
    nh_cmd ubus call "network.interface.$NH_WAN" status
    nh_log_match logread 'udhcpc|odhcp6c|pppd|netifd.*(wan|Interface)'
}
