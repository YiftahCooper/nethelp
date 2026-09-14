# 4: rtl8156b. Help is local metadata; sourcing this file runs no checks.
NH_ID=4
NH_NAME='rtl8156b'
NH_SUMMARY='WAN driver, negotiated Ethernet link and USB topology.'
NH_WHEN='Investigate dongle resets, wrong USB speed or a slow Ethernet link.'
NH_LOOK='Driver identity, speed, duplex, carrier and USB bus speed. Legacy name also works for other NICs.'
NH_LIMIT='A healthy link does not prove the ISP is forwarding traffic.'
nh_run() {
    nh_wan || return
    nh_cmd ethtool -i "$NH_PHY"
    nh_cmd ethtool "$NH_PHY"
    nh_optional ethtool --show-eee "$NH_PHY"
    nh_optional lsusb -t
}
