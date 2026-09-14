# 11: mtu-path. Help is local metadata; sourcing this file runs no checks.
NH_ID=11
NH_NAME='mtu-path'
NH_SUMMARY='Path-MTU discovery, with a clearly labelled DF fallback.'
NH_WHEN='Small requests work but larger transfers stall.'
NH_LOOK='Reported PMTU or explicit fragmentation-needed errors.'
NH_LIMIT='A silent large probe does not establish an exact MTU or distinguish filtering from loss.'
nh_run() {
    if [ "$NH_PLAN" = 1 ] || command -v tracepath >/dev/null 2>&1; then
      nh_cmd tracepath "-$NH_FAMILY" -n "$NH_TARGET"
    elif [ "$NH_FAMILY" = 4 ]; then
      nh_cmd ping -h
      if grep -q -- '-M' "$NH_TMP/command"; then
        nh_note 'Fallback: one 1500-byte IPv4 DF probe, NOT a path-MTU search.'
        nh_cmd ping -4 -n -c 1 -W 2 -M do -s 1472 "$NH_TARGET"
      else nh_note '[tracepath unavailable and ping has no confirmed DF option]'; NH_BROKEN=1; fi
    else nh_note '[tracepath required for this IPv6 MTU check]'; NH_BROKEN=1; fi
}
