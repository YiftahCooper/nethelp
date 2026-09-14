# 17: upstream-tls. Help is local metadata; sourcing this file runs no checks.
NH_ID=17
NH_NAME='upstream-tls'
NH_SUMMARY='Strict certificate-verified TLS to a DNS-over-TLS endpoint.'
NH_WHEN='Local DNS works inconsistently and encrypted upstream transport is suspect.'
NH_LOOK='Clock, connection errors, certificate verification and negotiated TLS.'
NH_LIMIT='A TLS handshake is not a DNS query. This check is DoT, not DoH.'
nh_run() {
    nh_cmd date -u
    nh_cmd openssl s_client -connect "$NH_TLS_ENDPOINT" -servername "$NH_TLS_NAME" -verify_hostname "$NH_TLS_NAME" -verify_return_error -brief
}
