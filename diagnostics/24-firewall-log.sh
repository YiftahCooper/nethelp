# 24: firewall-log. Help is local metadata; sourcing this file runs no checks.
NH_ID=24
NH_NAME='firewall-log'
NH_SUMMARY='Already-recorded firewall drops and firewall service errors.'
NH_WHEN='A rule or existing logged drop might explain failed traffic.'
NH_LOOK='Matching rule/device, drop/reject entries and rule load failures.'
NH_LIMIT='Unlogged traffic cannot be reconstructed; this check never enables tracing or logging.'
nh_run() {
    nh_log_match logread '(DROP|REJECT|fw4|nftables|firewall.*(error|fail))'
}
