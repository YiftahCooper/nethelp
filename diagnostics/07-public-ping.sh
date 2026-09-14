# 7: public-ping. Help is local metadata; sourcing this file runs no checks.
NH_ID=7
NH_NAME='public-ping'
NH_SUMMARY='Bounded ICMP reachability to a chosen target.'
NH_WHEN='After checking WAN state, test reachability independently of DNS using an IP.'
NH_LOOK='Replies, loss and round-trip time; repeat with another independent numeric target.'
NH_LIMIT='No reply alone does not prove an outage: ICMP may be filtered.'
nh_run() {
    nh_ping "$NH_TARGET"
}
