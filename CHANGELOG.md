# Changelog — GoAccess for Virtualmin

## 1.4.4 — 2026-09-23
- Displays the Virtualmin domain name in a prominent banner at the top of each generated GoAccess HTML report.
- Sets the HTML document title to `GoAccess - <domain>` for standalone reports accessed directly through Apache or Webmin.
- HTML-escapes the domain name, uses atomic report replacement, and preserves the existing report permissions workflow.

## 1.4.3 — 2026-09-23
- Replaced the free-text GoAccess log-format setting with dropdowns on both the standard Webmin Configuration page and the module-specific configuration page.
- Added server-side validation of the selected log format in both configuration save paths.
- Cron adjustment within 1.4.3: explicitly writes `*/1 * * * *` for a one-minute interval; default configuration now uses one minute.
- Detects GoAccess in `/usr/bin/goaccess` or `/usr/local/bin/goaccess` and requires GoAccess 1.9.3 or newer.

## 1.4.2 — 2026-09-23
- Added Webmin `config_post_save` hook so Configuration changes regenerate `/etc/cron.d/virtualmin-goaccess`.
- Retained 360-minute scheduling (`0 */6 * * *`) and fallback timestamp scheduling for other intervals.

## 1.4.1 — 2026-09-23
- Added Webmin module configuration field definitions.

## 1.4 — 2026-09-23
- Added project attribution: Frank Beckmann, FNH media KG.
- Added contact address and copyright notices.
- Added changelog.

## 1.3 — 2026-09-23
- Added information/license page and version display.

## 1.2 — 2026-09-23
- Added direct cron expressions for intervals including 360 minutes (6 hours).

## 1.1–1.1.4 — 2026-09-23
- Added a Virtualmin domain overview and Webmin-authenticated report access.
- Revised access checks and report delivery after reported runtime errors.

## 1.0 — 2026-09-23
- Extended configured update intervals to 10,080 minutes.

## 0.9 — 2026-09-23
- Added overview of accessible Virtualmin domains.

## 0.8 — 2026-09-23
- Linked scheduling configuration to the GoAccess update interval.

## 0.7 — 2026-09-23
- Added automatic cron installation and Webmin runtime initialization.

## 0.6 — 2026-09-23
- Added cron-based scheduling for SysVinit environments.
- Added initial processing of compressed rotated logs.

Note: Historical entries summarize earlier development versions; they are not a claim of completed end-to-end testing on every supported system.
