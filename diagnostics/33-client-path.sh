# 33: client-path. Help is local metadata; sourcing this file runs no checks.
NH_ID=33
NH_NAME='client-path'
NH_SUMMARY='Router-side routing and neighbour evidence for one explicit client.'
NH_WHEN='The router has Internet but a particular LAN client does not.'
NH_LOOK='Client neighbour/device, bridge/VLAN membership, lease and forwarding route/rules.'
NH_LIMIT='This does not observe the client DNS setting or prove its packets crossed the router.'
nh_run() {
    if [ -z "$NH_CLIENT" ]; then nh_note '[provide --client IP; this check does not scan the LAN]'; return; fi
    nh_cmd ip neigh show to "$NH_CLIENT"
    nh_optional bridge link show
    nh_optional bridge vlan show
    nh_cmd ip "-$NH_FAMILY" rule show
    nh_cmd ip "-$NH_FAMILY" route get "$NH_TARGET" from "$NH_CLIENT"
    nh_cmd nft -nn list ruleset
    if [ "$NH_PLAN" = 1 ] || [ -f /tmp/dhcp.leases ]; then
      nh_cmd awk -v "client=$NH_CLIENT" '$3==client {print}' /tmp/dhcp.leases
    fi
    nh_note 'For an ingress-specific policy route, add iif DEVICE to the displayed ip route get command.'
}
