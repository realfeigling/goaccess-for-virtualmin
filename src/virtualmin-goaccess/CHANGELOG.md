# Changelog — GoAccess for Virtualmin

## 1.4.4 — 2026-09-23
- Displays the Virtualmin domain name in a prominent banner at the top of each generated GoAccess HTML report.
- Sets the HTML document title to `GoAccess - <domain>` for standalone reports accessed directly through Apache or Webmin.
- HTML-escapes the domain name, uses atomic report replacement, and preserves the existing report permissions workflow.

## 1.4.3 — 2026-09-23
- Replaced the free-text GoAccess log-format setting with dropdowns on both the standard Webmin Configuration page and the module-specific configuration page.
- Added server-side validation of the selected log format in both configuration save paths.

- Cron adjustment within 1.4.3: explicitly writes `*/1 * * * *` for a one-minute interval; default configuration now uses one minute. Existing installations retain their saved interval until changed in Configuration.
- Detects GoAccess in `/usr/bin/goaccess` or `/usr/local/bin/goaccess` and reads its actual `--version` output.
- Requires GoAccess 1.9.3 or newer; missing, unrecognized, older, and prerelease versions are reported as incompatible.
- Shows installed version, executable path, minimum required version, and compatibility on the module overview and About page.
- Virtualmin feature availability and report generation check version compatibility before proceeding.
- Installation emits a warning if GoAccess is missing; the module can still be installed before GoAccess itself.

## 1.4.2 — 2026-09-23
- Added `config_info.pl` with Webmin `config_post_save` hook so saving the standard Webmin Configuration page regenerates `/etc/cron.d/virtualmin-goaccess` immediately.
- Validates the interval and URL path on standard configuration saves; restores the previous configuration if cron setup fails.
- Clears the scheduling timestamp after interval changes, including changes made through the standard Configuration page.
- Corrected `postinstall.pl` to expose Webmin's `module_install` callback for installation and upgrades.
- Retained 360-minute scheduling (`0 */6 * * *`) and fallback timestamp scheduling for other intervals.

## 1.4.1 — 2026-09-23
- Added Webmin module configuration field definitions (config.info) so the existing configuration page displays the URL path, update interval and log format.
- The module-specific GoAccess Configuration page remains the recommended place to save the update interval because it also reconciles the cron job.

## 1.4 — 2026-09-23
- Added project attribution: Frank Beckmann, FNH media KG.
- Added contact address and copyright notices.
- Added changelog file and link from the module overview.
- Retained existing GoAccess processing and scheduling from v1.3.

## 1.3 — 2026-09-23
- Added information/license page and version display.

## 1.2 — 2026-09-23
- Added direct cron expressions for intervals including 360 minutes (6 hours).
- Retained internal scheduling for intervals not directly representable by cron.

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

Note: Historical entries summarize earlier development versions; they are
not a claim of completed end-to-end testing on every supported system.
