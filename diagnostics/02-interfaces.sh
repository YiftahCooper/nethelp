# 2: interfaces. Help is local metadata; sourcing this file runs no checks.
NH_ID=2
NH_NAME='interfaces'
NH_SUMMARY='Logical interfaces, link state, addresses, bridges and VLANs.'
NH_WHEN='Check whether the expected WAN and LAN devices exist and are up.'
NH_LOOK='Device mapping, carrier, MTU, IPv4/IPv6 addresses and bridge membership.'
NH_LIMIT='An UP interface or an address does not prove Internet access.'
nh_run() {
    nh_wan
    nh_cmd ip -d -s link show
    nh_cmd ip address show
    nh_optional bridge link show
    nh_optional bridge vlan show
}
