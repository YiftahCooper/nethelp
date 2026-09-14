# 6: gateway-ping. Help is local metadata; sourcing this file runs no checks.
NH_ID=6
NH_NAME='gateway-ping'
NH_SUMMARY='Selected next-hop neighbour state and a bounded ping.'
NH_WHEN='Separate a local/upstream first-hop problem from a wider outage.'
NH_LOOK='The selected device and gateway, neighbour resolution and ping replies.'
NH_LIMIT='A gateway may ignore ping; PPP or on-link routes may have no gateway address.'
nh_run() {
    nh_wan || return
    nh_capture ip "-$NH_FAMILY" route get "$NH_TARGET"
    [ "$NH_PLAN" = 0 ] || { nh_cmd ping "-$NH_FAMILY" -n -c "$NH_COUNT" -W 2 '<selected-next-hop>'; return; }
    route=$NH_DATA
    gateway=$(printf '%s\n' "$route" | awk '{for(i=1;i<NF;i++)if($i=="via")print $(i+1)}')
    dev=$(printf '%s\n' "$route" | awk '{for(i=1;i<NF;i++)if($i=="dev")print $(i+1)}')
    case "$gateway" in ''|*[!0-9a-fA-F:.%]*) nh_note '[no unique numeric next hop; consult route output, including PPP/on-link routes]'; return;; esac
    case "$dev" in ''|*[!a-zA-Z0-9_.:-]*) nh_note '[route device ambiguous]'; return;; esac
    nh_cmd ip neigh show dev "$dev"
    nh_cmd ping "-$NH_FAMILY" -n -I "$dev" -c "$NH_COUNT" -W 2 "$gateway"
}
