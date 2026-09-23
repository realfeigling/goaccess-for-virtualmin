#!/usr/bin/perl
require './virtualmin-goaccess-lib.pl';
&ui_print_header(undef, 'About Virtualmin GoAccess', '', undef, 1, 1);
print '<h2>GoAccess for Virtualmin v1.4.4</h2>';
print '<p>Copyright &copy; 2026 Frank Beckmann, FNH media KG</p>';
my ($ok, $binary, $installed, $reason) = ga_version_status();
print '<p><strong>GoAccess:</strong> '.&html_escape($ok ? "$installed ($binary) — compatible" : $reason).' (minimum '.&html_escape(ga_min_version()).')</p>';
print '<p>GoAccess is a separate project. Its copyright and license remain with its respective authors.</p>';
print '<p>Project: GoAccess for Virtualmin<br>Author: Frank Beckmann<br>Company: FNH media KG<br>Contact: <a href="mailto:beckmann@fnh.de">beckmann@fnh.de</a></p>';
print '<p>Plugin license: not yet specified. No open-source license is implied.</p>';
print '<p><a href="changelog.cgi">Changelog</a></p>';
&ui_print_footer('/', 'Virtualmin');
