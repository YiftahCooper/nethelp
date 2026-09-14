# 23: dns-log. Help is local metadata; sourcing this file runs no checks.
NH_ID=23
NH_NAME='dns-log'
NH_SUMMARY='Retained DNS service errors, not browsing query history.'
NH_WHEN='DNS is intermittent or upstream-specific.'
NH_LOOK='Timeout, connection, TLS, validation and service restart events.'
NH_LIMIT='A missing log entry is not proof that a DNS failure did not happen.'
nh_run() {
    nh_log_match logread '(AdGuardHome|dnsmasq|unbound|stubby).*(error|fail|timeout|refused|start|stop|certificate|upstream.*(connect|unreach))'
}
