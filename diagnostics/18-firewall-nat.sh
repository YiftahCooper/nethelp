# 18: firewall-nat. Help is local metadata; sourcing this file runs no checks.
NH_ID=18
NH_NAME='firewall-nat'
NH_SUMMARY='Active firewall/NAT rules and selected routing context.'
NH_WHEN='Router-originated Internet works but LAN clients cannot get out.'
NH_LOOK='Forwarding/masquerade rules, counters, relevant zones and flow offload.'
NH_LIMIT='Router probes do not traverse the same forwarding path as client traffic.'
nh_run() {
    nh_cmd nft -nn list ruleset
    nh_cmd ip "-$NH_FAMILY" route get "$NH_TARGET"
    nh_cmd cat /proc/sys/net/ipv4/ip_forward /proc/sys/net/ipv6/conf/all/forwarding
}
