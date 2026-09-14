# 26: receipt. Help is local metadata; sourcing this file runs no checks.
NH_ID=26
NH_NAME='receipt'
NH_SUMMARY='Save selected diagnostics with version, time and command output.'
NH_WHEN='Keep evidence for later comparison or share a reviewed report with a helper.'
NH_LOOK='Complete versus partial collection, actual commands and the private report path.'
NH_LIMIT='Reports contain real addresses and operational details. Secret filtering is best effort.'
nh_run() {
    nh_note 'Use nethelp 26 1 7 13 to save those checks, or --output FILE with any selection.'
    nh_note '26 alone saves a practical outage bundle. It does not include a long watch or flow dump.'
}
