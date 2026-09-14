# 28: traffic-history. Help is local metadata; sourcing this file runs no checks.
NH_ID=28
NH_NAME='traffic-history'
NH_SUMMARY='vnStat historical totals with timestamp and storage context.'
NH_WHEN='Compare traffic history before and after an outage.'
NH_LOOK='Readable totals even if stale/stopped, database age and backing storage.'
NH_LIMIT='Historical totals are not live speed. RAM-backed history is lost on reboot.'
nh_run() {
    nh_wan || return
    nh_optional pidof vnstatd
    nh_capture vnstat --json -i "$NH_DEV"
    [ "$NH_PLAN" = 0 ] || { nh_cmd jsonfilter -i '<vnstat-json>' -e '@.interfaces[0]'; return; }
    [ "$NH_CAPTURE_RC" = 0 ] || { nh_note '[traffic history unavailable]'; NH_BROKEN=1; return; }
    printf '%s\n' "$NH_DATA" > "$NH_TMP/vnstat.json"
    nh_capture jsonfilter -i "$NH_TMP/vnstat.json" -e '@.interfaces[0].name' -e '@.interfaces[0].created.timestamp' -e '@.interfaces[0].updated.timestamp' -e '@.interfaces[0].traffic.total.rx' -e '@.interfaces[0].traffic.total.tx'
    values=$NH_DATA
    name=$(printf '%s\n' "$values" | sed -n '1p')
    created=$(printf '%s\n' "$values" | sed -n '2p')
    updated=$(printf '%s\n' "$values" | sed -n '3p')
    rx=$(printf '%s\n' "$values" | sed -n '4p')
    tx=$(printf '%s\n' "$values" | sed -n '5p')
    case "$created:$updated:$rx:$tx" in *[!0-9:]*) nh_note '[unrecognized vnStat counters/timestamps; raw JSON above retained]'; NH_BROKEN=1; return;; esac
    [ -n "$created" ] && [ -n "$updated" ] && [ -n "$rx" ] && [ -n "$tx" ] && [ "$name" = "$NH_DEV" ] || { nh_note '[incomplete or wrong-interface history; raw JSON retained]'; NH_BROKEN=1; return; }
    nh_capture date +%s
    now=$NH_DATA
    case "$now" in ''|*[!0-9]*) nh_note '[current time unavailable]'; return;; esac
    save=5 db=/var/lib/vnstat
    if [ -f /etc/vnstat.conf ]; then
      nh_capture awk '$1=="SaveInterval" || $1=="DatabaseDir" {print}' /etc/vnstat.conf
      save_config=$(printf '%s\n' "$NH_DATA" | awk '$1=="SaveInterval"{print $2}')
      db_config=$(printf '%s\n' "$NH_DATA" | awk '$1=="DatabaseDir"{gsub(/"/,"",$2); print $2}')
      case "$save_config" in ''|*[!0-9]*) ;; *) save=$save_config;; esac
      [ -z "$db_config" ] || db=$db_config
    fi
    age=$((now - updated)); fresh=$((save * 120 + 60))
    status=STALE
    [ "$age" -lt 0 ] && status=CLOCK_MISMATCH
    [ "$age" -lt 0 ] || [ "$age" -gt "$fresh" ] || status=FRESH
    printf 'status=%s\ninterface=%s\nupdated_epoch=%s\nupdate_age_seconds=%s\nfreshness_threshold_seconds=%s\nrx_bytes=%s\ntx_bytes=%s\n' "$status" "$name" "$updated" "$age" "$fresh" "$rx" "$tx"
    nh_cmd readlink -f "$db"
    nh_cmd df -T "$db"
    nh_note 'Storage is determined above, not assumed. Custom daemon --config arguments need separate inspection.'
}
