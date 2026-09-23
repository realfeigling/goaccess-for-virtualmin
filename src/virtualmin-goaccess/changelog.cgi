#!/usr/bin/perl
require './virtualmin-goaccess-lib.pl';
&ui_print_header(undef, 'Changelog — GoAccess for Virtualmin', '', undef, 1, 1);
print '<h2>Changelog</h2>';
print '<p><strong>v1.4.4 (2026-09-23)</strong>: Domain banner and domain-specific HTML page title in generated reports; existing reports are labeled on their next update check.</p>';
print '<p><strong>v1.4.3 (2026-09-23)</strong>: GoAccess installation and minimum version (1.9.3) checks, visible status and compatibility enforcement.</p>';
print '<p><strong>v1.4.2 (2026-09-23)</strong>: Standard Webmin configuration now updates cron automatically; install hook corrected.</p>';
print '<p><strong>v1.4.1</strong>: Added configuration fields.</p>';
print '<p><strong>v1.4 (2026-09-23)</strong>: Project attribution, copyright, contact details and changelog.</p>';
print '<p><strong>v1.3</strong>: Information page and version display.</p>';
print '<p><strong>v1.2</strong>: Cron schedules including 360-minute intervals.</p>';
print '<p><strong>v1.1–1.1.4</strong>: Domain overview, authenticated report access and fixes.</p>';
print '<p><strong>v1.0</strong>: Extended intervals up to 7 days.</p>';
print '<p><strong>v0.9</strong>: Accessible domain overview.</p>';
print '<p><strong>v0.8</strong>: Configuration-driven scheduling.</p>';
print '<p><strong>v0.7</strong>: Automatic cron installation.</p>';
print '<p><strong>v0.6</strong>: SysVinit cron support and compressed log history.</p>';
print '<p>Full history: CHANGELOG.md in the module directory.</p>';
&ui_print_footer('/', 'Virtualmin');
