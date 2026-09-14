# 3: routes-neighbours. Help is local metadata; sourcing this file runs no checks.
NH_ID=3
NH_NAME='routes-neighbours'
NH_SUMMARY='IPv4/IPv6 routes, policy rules and neighbours.'
NH_WHEN='Internet fails despite a working link, or VPN/routing may interfere.'
NH_LOOK='The route and source selected for the target; missing default routes and FAILED neighbours.'
NH_LIMIT='A routing table is intent, not proof packets reach their destination.'
nh_run() {
    nh_cmd ip -4 rule show
    nh_cmd ip -6 rule show
    nh_cmd ip -4 route show table all
    nh_cmd ip -6 route show table all
    nh_cmd ip "-$NH_FAMILY" route get "$NH_TARGET"
    nh_cmd ip neigh show
}
