# Nethelp

**Internet broken, but you can still SSH into your OpenWrt router? Start here.**

Nethelp is a small, read-only collection of outage diagnostics. Choose a check, see the exact commands, and get their output. It helps you separate link, routing, DNS, TLS, firewall, resource and intermittent-connectivity problems without guessing which shell commands to remember.

It does **not** repair your network, restart services, renew leases, change firewall rules, upgrade packages or upload reports. It is not a speed-test service or a background monitor.

Version: **3.0.0-rc1 — release candidate.** Installation, the interactive menu and the router-status diagnostic have been verified on an OpenWrt router. Not every diagnostic or supported configuration has been exercised on real hardware.

License: [GNU GPLv3](LICENSE), preserving the license selected for the repository.

## Start with three commands

~~~sh
nethelp help 29 6 7 13
nethelp 29 6 7 13
nethelp 26 29 6 7 13
~~~

The first explains the checks without running them. The second runs WAN status, gateway ping, public-IP ping and local DNS. The third saves that same selection in a private report and prints its location.

Or run **nethelp** for the flat interactive menu. After a check, only a small prompt appears. Your output stays above it: no screen clearing, repeated full menu or automatic pager.

## Choosing checks during an outage

| What you observe | Useful starting selection | What you are separating |
|---|---|---|
| Everything is down | 29 6 7 13 | WAN acquisition, first hop, public reachability, DNS |
| A link is missing or repeatedly disconnects | 2 4 5 22 | Interface mapping, driver/link/USB state, counters, events |
| IP connectivity works but names fail | 12 13 16 31 | Local listener, resolver, alternate paths, UDP versus TCP |
| DNS works but HTTPS does not | 8 9 17 | TCP, HTTPS and encrypted DNS transport |
| Suspected DNS failure prevents HTTPS tests | 9 30 | Normal HTTPS versus a known host/IP mapping |
| The router has Internet, one client does not | 33 18 | Client-specific router context and forwarding rules |
| Slow or intermittent Internet | 10 20 21 32 | Path loss, queues, growing errors, timestamped observations |
| Unexpected reboot or severe slowdown | 1 25 | Resources/power/current boot and retained crash evidence |
| Want to keep evidence for a chatbot or ISP | 26 plus your chosen numbers | Full selected output in a private text report |

**Do not mistake a failed ping for proof of an ISP fault.** If a numeric TCP connection and verified HTTPS work while ping fails, ICMP may simply be filtered. Conversely, a DHCP lease proves address acquisition—not working Internet forwarding.

## Selection and help

~~~sh
nethelp 1 2
nethelp 1,2
nethelp 1, 2
nethelp router-status interfaces

nethelp help 7
nethelp -h 7
nethelp 7 -h
nethelp help 6 7 13

nethelp --commands 7 13
nethelp --parallel 7 13
~~~

- Numbers and names can be mixed. Duplicate selections run once. A typo rejects the **entire** selection before any diagnostic runs.
- **help**, **-h** and **--help** all explain only. They do not contact the router/network, read a private config or execute diagnostics. There is no -why option.
- **--commands** shows recipes, using labelled placeholders for values only runtime discovery can supply. It does not prove those commands are supported on this machine.
- Execution is sequential by default. **--parallel** runs at most two diagnostics concurrently and prints complete result groups in selection order. Counter sampling, the watch and saved reports use sequential execution to avoid contaminating observations.
- In the menu enter numbers/names, **help 7**, **menu** to redisplay the list, or **q** to quit. Direct command-line selections exit when finished.
- Without a terminal or a selection, Nethelp prints help and exits; it will not hang waiting for input.

## Diagnostic reference

Every entry has its own source file. Each contains its purpose, when to use it, what to look for, limitations, and the commands themselves. Shared mechanics are in [lib/common.sh](lib/common.sh).

| # | Diagnostic and source | What it checks |
|---|---|---|
| 1 | [router-status](diagnostics/01-router-status.sh) | System time, uptime, resources, power and temperature. |
| 2 | [interfaces](diagnostics/02-interfaces.sh) | Logical interfaces, link state, addresses, bridges and VLANs. |
| 3 | [routes-neighbours](diagnostics/03-routes-neighbours.sh) | IPv4/IPv6 routes, policy rules and neighbours. |
| 4 | [rtl8156b](diagnostics/04-rtl8156b.sh) | WAN driver, negotiated Ethernet link and USB topology. |
| 5 | [wan-errors](diagnostics/05-wan-errors.sh) | WAN counters, receive processing and CPU steering state. |
| 6 | [gateway-ping](diagnostics/06-gateway-ping.sh) | Selected next-hop neighbour state and a bounded ping. |
| 7 | [public-ping](diagnostics/07-public-ping.sh) | Bounded ICMP reachability to a chosen target. |
| 8 | [tcp443](diagnostics/08-tcp443.sh) | A TCP connection without DNS, TLS or HTTP. |
| 9 | [https-timing](diagnostics/09-https-timing.sh) | Verified HTTPS with DNS, TCP, TLS and response timings. |
| 10 | [mtr](diagnostics/10-mtr.sh) | A finite hop-by-hop path report. |
| 11 | [mtu-path](diagnostics/11-mtu-path.sh) | Path-MTU discovery, with a clearly labelled DF fallback. |
| 12 | [dns-listeners](diagnostics/12-dns-listeners.sh) | TCP and UDP listeners plus local DNS processes. |
| 13 | [adguard-query](diagnostics/13-adguard-query.sh) | A question to the configured primary DNS resolver. |
| 14 | [dnsmasq-query](diagnostics/14-dnsmasq-query.sh) | The same question to an explicitly selected secondary resolver. |
| 15 | [dnssec](diagnostics/15-dnssec.sh) | Valid and deliberately bogus signed DNS responses. |
| 16 | [dns-compare](diagnostics/16-dns-compare.sh) | The same DNS question through system, local, ISP and public paths. |
| 17 | [upstream-tls](diagnostics/17-upstream-tls.sh) | Strict certificate-verified TLS to a DNS-over-TLS endpoint. |
| 18 | [firewall-nat](diagnostics/18-firewall-nat.sh) | Active firewall/NAT rules and selected routing context. |
| 19 | [conntrack](diagnostics/19-conntrack.sh) | Connection-tracking occupancy and error statistics. |
| 20 | [sqm](diagnostics/20-sqm.sh) | Configured SQM instances and all active queueing disciplines. |
| 21 | [counter-delta](diagnostics/21-counter-delta.sh) | Two interface counter samples and changes between them. |
| 22 | [wan-log](diagnostics/22-wan-log.sh) | Retained WAN, driver, DHCP and PPP events. |
| 23 | [dns-log](diagnostics/23-dns-log.sh) | Retained DNS service errors, not browsing query history. |
| 24 | [firewall-log](diagnostics/24-firewall-log.sh) | Already-recorded firewall drops and firewall service errors. |
| 25 | [reboot-log](diagnostics/25-reboot-log.sh) | Current boot identity and retained crash/power evidence. |
| 26 | [receipt](diagnostics/26-receipt.sh) | Save selected diagnostics with version, time and command output. |
| 27 | [commands](diagnostics/27-commands.sh) | Offline command recipes from the diagnostic implementations. |
| 28 | [traffic-history](diagnostics/28-traffic-history.sh) | vnStat historical totals with timestamp and storage context. |
| 29 | [wan-status](diagnostics/29-wan-status.sh) | WAN protocol, acquisition state, addresses, routes and advertised DNS. |
| 30 | [https-no-dns](diagnostics/30-https-no-dns.sh) | Verified HTTPS using a supplied host-to-IP mapping. |
| 31 | [dns-transport](diagnostics/31-dns-transport.sh) | The identical DNS question over UDP and TCP. |
| 32 | [connectivity-watch](diagnostics/32-connectivity-watch.sh) | A short, finite timestamped reachability watch. |
| 33 | [client-path](diagnostics/33-client-path.sh) | Router-side routing and neighbour evidence for one explicit client. |

## Useful customization

~~~sh
# Logical WAN renamed, or hardware device different from its L3 interface:
nethelp 2 4 29 --wan wan --interface pppoe-wan --physical eth2

# Compare another numeric Internet destination:
nethelp 7 8 --target 9.9.9.9

# IPv6 has IPv6 defaults; record type is independent of transport family:
nethelp 7 --family 6
nethelp 13 --family 6 --resolver ::1 --type AAAA

# A separate local DNS backend is optional and must be selected:
nethelp 14 16 --secondary 127.0.0.1 --secondary-port 54

# DNS query and protocol comparison:
nethelp 13 31 --domain example.com --type AAAA --resolver 127.0.0.1
nethelp 10 --protocol tcp --port 443 --target 1.1.1.1

# Observe briefly; this is not a daemon:
nethelp 32 --seconds 60 --interval 5
nethelp 21 --interface eth2 --interval 10

# Router-side investigation for one client; documentation-only sample address:
nethelp 33 --client 192.0.2.25
nethelp 19 --entries --client 192.0.2.25
~~~

For check 30, supply **--url https://HOST/** and **--connect-ip IP** using a mapping known to be current. Nethelp preserves the HTTPS hostname, SNI and certificate verification using curl --resolve. A guessed/stale IP gives misleading failures, so no permanent service-IP mapping is bundled.

Check 17 uses a configurable DNS-over-TLS endpoint and certificate name:
~~~sh
nethelp 17 --tls-endpoint 1.1.1.1:853 --tls-name cloudflare-dns.com
~~~
It verifies a TLS handshake, not a DNS transaction. It is not a DoH test.

### Local configuration

Copy [config/nethelp.conf.example](config/nethelp.conf.example) to **/etc/nethelp.conf** if you want persistent overrides, or select another file with **--config FILE**. Configuration is plain key=value data, **not executable shell**. Do not put credentials in it. No configuration is loaded from the current directory.

Precedence: **CLI override → local config → runtime device discovery → documented default**.

Defaults: logical WAN **wan**; L3/physical devices discovered from its ubus status; public target **1.1.1.1** (IPv6: **2606:4700:4700::1111**); primary resolver **127.0.0.1:53** (IPv6: **[::1]:53**); question **example.com A**; HTTPS **https://example.com/**; DoT **1.1.1.1:853**, certificate name **cloudflare-dns.com**. These public control endpoints are not your private topology.

A secondary resolver is disabled until specified. Its default port is 54 if enabled. The selected WAN is not inferred from every VPN/default route: choose --wan for another logical uplink. Gateway ping shows the route actually selected for the target; that may be a VPN rather than the named WAN. Device overrides do not rewrite routing. --interface binds ping and selects device-oriented checks; other protocols use existing system routing unless their displayed command says otherwise.

**--count** 1–20 (default 3), **--timeout** 1–60 seconds per command (default 10), **--interval** 1–60 seconds (default 5), **--seconds** 1–300 seconds for the watch (default 30). A multi-command diagnostic can take longer than one timeout. The watch bounds its own observation window using monotonic uptime; process cleanup may add up to two seconds.

## Understanding the output

Each section starts with its number/name, then dollar-prefixed commands and native output. Nonzero command exits remain visible.

- **collection=complete** means collection finished without a detected collector error. It does **not** mean Internet access is healthy.
- **collection=incomplete**, unavailable-command markers or time-limit markers mean some requested evidence could not be obtained.
- A normal failed network probe is evidence, not automatically a broken collector.
- Empty or unavailable logs are labelled as such. Nethelp searches the **whole retained log**, not an arbitrary last 100/500 lines, but cannot recover overwritten records.
- Some old ip/ethtool implementations lack an option. Their errors stay visible; do not interpret them as an empty table.
- AQM drops/HTB overlimits can be intentional. Driver receive errors, kernel drops and SQM drops are different counters.
- Router-originated probes do not prove that LAN-client forwarding works. Check 33 provides router-side context but cannot see the client DNS configuration.
- DNS responses may be cached, filtered or intercepted. An external server address is not proof the request reached that server.
- DNSSEC DO asks for DNSSEC records; it is not a claim of local cryptographic validation. Compare valid/bogus/CD results and the AD flag cautiously.
- vnStat totals remain visible when stale or the daemon is stopped. Freshness uses twice the configured SaveInterval plus 60 seconds; it is a heuristic, not a guarantee. The backing filesystem is shown rather than assumed persistent.

Exit codes: **0** completed collection/help/preview (inspect individual probe results), **2** invalid request/configuration or an existing report destination, **3** incomplete collection/save failure, **130** cancellation where handled. SIGTERM/terminal behavior can differ between shells.

## Reports, privacy and chatbots

~~~sh
nethelp 26 1 7 13
nethelp 29 7 13 --output /tmp/outage-report.txt
~~~

Reports use private permissions. Existing reports are never overwritten; a failed save can leave a clearly named **.partial** file. Automatically created reports live under **/tmp/nethelp-report.XXXXXX/** and are normally **lost on reboot**. Copy evidence elsewhere if you need it later.

**Local results deliberately preserve IP addresses and MAC addresses.** Those are important evidence. The filter removes recognizable password/token/header fields and private-key blocks, but cannot guarantee that arbitrary command output is secret-free. Review reports before sharing. Conntrack flow entries require an explicit client selection; DNS logs focus on errors rather than browsing query history.

The public repository contains source, documentation and synthetic tests—not anyone's private configuration, receipts, logs, keys or network inventory. Do not commit those files, screenshots or an entire router-management workspace.

For a chatbot that does not know Nethelp, give it this repository URL and the version:
> I use Nethelp 3.0.0-rc1 from https://github.com/YiftahCooper/nethelp. I can SSH into the OpenWrt router, but Internet is down/slow/intermittent. Read the README and the linked diagnostic source. Ask for the smallest useful selection, and distinguish missing evidence from a healthy result.

A chatbot cannot automatically know a private/local tool or necessarily browse GitHub. If it cannot open the repository, paste the relevant **nethelp help ITEM** output and diagnostic module. Keep the README on your laptop/router so it remains accessible without Internet.

## Installation and updates

Runtime: **POSIX sh/BusyBox ash**, standard OpenWrt utilities, and **GNU coreutils timeout** with **-k**. No Python, Node, web UI or background daemon is needed on the router.

Optional tools are used by individual checks: **ubus/jsonfilter**, **ip**, **ethtool**, **lsusb**, **drill**, **curl**, **openssl**, **mtr**, **tracepath**, **nft**, **conntrack**, **tc**, and **vnstat**. **netcat-openbsd** supplies the confirmed **nc -z** TCP probe; a BusyBox nc without that option is labelled unsupported. Thermal and Raspberry Pi power tools are optional. Missing optional tools do not prevent help or unrelated checks.

Do not install a huge bundle blindly. Use the check you need, inspect its missing-tool message, then install the corresponding package for your exact OpenWrt release. Package names/availability differ across versions; this candidate does not transact packages.

**Install from a Git clone or a downloaded release. No APK packaging is needed.** Git is only a way to obtain/update the source; it is not a Nethelp runtime dependency. If Git is not already on the router, download/extract the release instead of installing Git just for this tool.

To obtain the source with Git:
~~~sh
git clone https://github.com/YiftahCooper/nethelp.git
cd nethelp
~~~
Alternatively, use GitHub's **Code → Download ZIP**, extract it, and copy the extracted directory to the router. GitHub-generated source archives may use a directory name such as **nethelp-main**. Only archives made with this project's builder use **nethelp-3.0.0-rc1** and include **SHA256SUMS**.

On the router, in its **SSH shell as root**, enter the cloned or extracted Nethelp directory and run:
~~~sh
sh install.sh
~~~
There are no prompts. The installer prints the installed command, check result, backup location and an exact rollback command. It should take seconds on a typical router; it does not run Internet probes. If it reports a failure, read that error rather than proceeding as though the upgrade succeeded.

The installer copies all 33 diagnostic modules, the shared runner, README, licence and example configuration to a private installation directory under **/usr/lib/nethelp-releases/**. It verifies copied bytes, shell syntax, help and a harmless local command through the real timeout/output runner. Then it replaces **/usr/bin/nethelp** with a launcher in one rename and checks help again. A failed post-switch check automatically restores the previous launcher.

The previous launcher is backed up. Old modules and older installation directories remain untouched, so that backup can still run. **/etc/nethelp.conf**, reports, router settings, packages and network services are not changed. No reboot or observation period is required. Runtime files are copied out of the checkout, so a later **git pull** cannot silently alter the active command. After obtaining an update, run **sh install.sh** again to activate it.

Use the exact **rollback=sh '.../rollback.sh'** command printed by your installation if you want the previous command back. It refuses to undo a newer installation or an independently changed launcher. A fresh installation with no previous command rolls back by removing only the launcher. Backups are not automatically deleted; do not remove an older directory while a retained launcher depends on it.

An interrupted install keeps its evidence and recovery script under its installation directory. Before the launcher switch, the old command is unchanged; after the switch, it points to a complete copy. A power cut or SIGKILL cannot run the cleanup trap: after confirming no installer is still running, remove the empty **/usr/lib/nethelp-releases/install.lock** directory with **rmdir**, then rerun the installer or use that installation's rollback script. This is an exceptional recovery step, not part of normal installation. Atomic rename protects against partial file sets, not arbitrary storage corruption.

For a non-system installation, use **sh install.sh --prefix /an/existing/writable/directory** and run its **bin/nethelp**. Keep this directory private and owned by the account that will execute Nethelp. The normal router installation is root-owned and intended for root's diagnostic sessions.

For inspection without installation, the release archive contains one top-level **nethelp-3.0.0-rc1/** directory. You can run **sh bin/nethelp help 7** directly from it. A supplied **SHA256SUMS** is checked during installation; a Git checkout without that manifest is treated as the source you selected. A checksum verifies consistency, not the trustworthiness of the source: obtain code from the intended repository/release and inspect it before running as root.

Offline tests and one live installation/basic diagnostic check do not guarantee compatibility with every router. The project does not self-update or download code during installation.

## Source and verification

- [bin/nethelp](bin/nethelp): entry point.
- [install.sh](install.sh): standalone install/update, automatic backup and local checks.
- [diagnostics/](diagnostics/): one directly accessible file per menu entry.
- [lib/common.sh](lib/common.sh): selection, config, bounded execution, filtering and reporting.
- [tests/](tests/): offline regressions; fake DNS programs never contact real resolvers.
- [tools/build.py](tools/build.py): explicit publication allowlist, text/privacy checks, deterministic tar and SHA-256 manifest.
- [docs/SOURCES.md](docs/SOURCES.md): upstream command references.

Development tests require Python 3 on the **development computer**, not the router:
~~~sh
python -m unittest discover -s tests -v
python tools/build.py --output-dir ../dist
~~~
NETHELP_TEST_SHELL selects another shell. For a BusyBox executable the suite invokes its ash applet. NETHELP_TIMEOUT_BIN can select a GNU timeout executable. These are local developer/environment overrides, never downloaded or enabled by Nethelp.

Offline tests do not prove your NIC, ISP, DNS servers or router package versions work. Live acceptance is a separate, small supervised step—not another 24-hour gate for a read-only script.
