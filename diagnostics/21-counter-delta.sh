# 21: counter-delta. Help is local metadata; sourcing this file runs no checks.
NH_ID=21
NH_NAME='counter-delta'
NH_SUMMARY='Two interface counter samples and changes between them.'
NH_WHEN='Find whether errors or drops increase during a reproducible problem.'
NH_LOOK='RX/TX packet, byte, error and drop deltas with elapsed time and reset detection.'
NH_LIMIT='Other traffic contributes. Recreating a device or rebooting invalidates a simple delta.'
nh_run() {
    nh_wan || return
    if [ "$NH_PLAN" = 1 ]; then
      nh_cmd cat '/sys/class/net/<device>/statistics/<counter>'
      nh_cmd sleep "$NH_INTERVAL"
      nh_note 'Repeat sample, retain both samples, calculate deltas unless counters/identity reset.'
      return
    fi
    nh_sample_counters "$NH_DEV" "$NH_TMP/before" || return
    NH_TIMEOUT=$((NH_INTERVAL + 2)); nh_cmd sleep "$NH_INTERVAL"
    nh_sample_counters "$NH_DEV" "$NH_TMP/after" || return
    nh_cmd awk '
    FNR==NR {before[$1]=$2; next}
    $1=="boot" || $1=="ifindex" {if(before[$1]!=$2) reset=1; next}
    {after[$1]=$2}
    END {
     if(reset) {print "delta=unavailable (boot/interface identity changed)"; exit}
     print "elapsed_seconds=" after["time"]-before["time"]
     for(k in after) if(k!="time") {
      if(after[k]<before[k]) print k "_delta=unavailable (counter reset)"
      else printf "%s_delta=%.0f\n",k,after[k]-before[k]
     }
    }' "$NH_TMP/before" "$NH_TMP/after"
}
