# 8: tcp443. Help is local metadata; sourcing this file runs no checks.
NH_ID=8
NH_NAME='tcp443'
NH_SUMMARY='A TCP connection without DNS, TLS or HTTP.'
NH_WHEN='Ping fails or you need to isolate TCP reachability from DNS and certificates.'
NH_LOOK='TCP connect success, refusal or timeout for a numeric --target and --port.'
NH_LIMIT='An open TCP port does not prove TLS, DNS, HTTP or other sites work.'
nh_run() {
    case "$NH_TARGET" in *[!0-9a-fA-F:.]*) nh_note '[tcp443 requires a numeric --target, not a hostname]'; NH_BROKEN=1; return;; esac
    case "$NH_TARGET" in
        *:*) ;; # Colon-containing input cannot be a DNS hostname.
        *)
            if ! printf '%s\n' "$NH_TARGET" | awk -F. 'NF!=4{exit 1} {for(i=1;i<=NF;i++)if($i!~/^[0-9]+$/ || $i>255)exit 1}'; then
                nh_note '[tcp443 requires a numeric IPv4 or IPv6 target]'; NH_BROKEN=1; return
            fi;;
    esac
    if [ "$NH_PLAN" = 0 ]; then
      nh_cmd nc -h
      if ! grep -Eq -- '(^|[[:space:]])-z|[-[][^]]*z' "$NH_TMP/command"; then
        nh_note '[nc lacks confirmed -z support; use netcat-openbsd for a no-payload TCP probe]'
        NH_BROKEN=1; return
      fi
    fi
    nh_cmd nc "-$NH_FAMILY" -z -v -w 3 "$NH_TARGET" "$NH_PORT"
}
