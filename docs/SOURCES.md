# Command references

Consulted for the 3.0.0-rc1 design. Runtime output remains authoritative for the installed tool version.

- [OpenWrt ubus](https://openwrt.org/docs/techref/ubus): logical interface status, l3_device, device, routes and advertised DNS.
- [OpenWrt network scripting](https://openwrt.org/docs/guide-developer/network-scripting): logical versus runtime devices.
- [curl manual](https://curl.se/docs/manpage.html): -q, --noproxy, --resolve, verification and cumulative timing fields.
- [OpenSSL 3.5 s_client](https://docs.openssl.org/3.5/man1/openssl-s_client/): -verify_return_error and -verify_hostname.
- [ldns drill source manual](https://github.com/NLnetLabs/ldns/blob/develop/drill/drill.1.in): -4/-6, -t, -D, -o CD, ports and record types.
- [MTR source](https://github.com/traviscross/mtr): finite report cycles and protocol options.
- [Linux conntrack sysctls](https://docs.kernel.org/networking/nf_conntrack-sysctl.html): occupancy and maximum.
- [conntrack manual](https://netfilter.org/projects/conntrack-tools/conntrack-manpage.html): statistics and source filtering.
- [vnStat configuration](https://humdi.net/vnstat/man/vnstat.conf.html): SaveInterval in minutes and database location.
- [GNU timeout](https://www.gnu.org/software/coreutils/manual/html_node/timeout-invocation.html): timeout status and signal handling.

This is not a claim that every target package/version has been exercised. BusyBox applet options vary. Nethelp retains unsupported-option errors and does not silently substitute a different conclusion.
