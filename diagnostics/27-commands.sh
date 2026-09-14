# 27: commands. Help is local metadata; sourcing this file runs no checks.
NH_ID=27
NH_NAME='commands'
NH_SUMMARY='Offline command recipes from the diagnostic implementations.'
NH_WHEN='Learn or verify the commands without probing anything.'
NH_LOOK='The actual recipe; angle-bracket values are runtime-discovered placeholders.'
NH_LIMIT='A recipe preview cannot know live topology or select runtime capability fallbacks.'
nh_run() {
    NH_PLAN=1
    for recipe in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 28 29 30 31 32 33; do nh_execute "$recipe"; done
}
