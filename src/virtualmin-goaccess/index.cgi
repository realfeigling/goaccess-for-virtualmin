#!/usr/bin/perl
require './virtualmin-goaccess-lib.pl';
&ReadParse();
&ui_print_header(undef, 'GoAccess Web Statistics', '', undef, 1, 1);
sub ga_urlencode { my $v = shift; $v =~ s/([^A-Za-z0-9_.~-])/sprintf('%%%02X', ord($1))/eg; return $v; }

# The module ACL's doms field is populated by feature_webmin for
# Virtualmin domain administrators. Do not expose other tenants' reports.
my ($remote, $is_master, $allowed) = ga_acl_context();
my @ds = grep { ga_domain_accessible($_, $remote, $is_master, $allowed) }
         &virtual_server::list_domains();
@ds = sort { $a->{'dom'} cmp $b->{'dom'} } @ds;
my $selected = $in{'dom'} || '';
my ($d) = grep { $_->{'dom'} eq $selected } @ds;

if ($selected && !$d) {
    print '<p>Unknown or inaccessible domain</p>';
}

my ($version_ok, $binary, $installed_version, $version_error) = ga_version_status();
print &ui_table_start('GoAccess installation', undef, 2);
print &ui_table_row('Required version', &html_escape(ga_min_version()).' or newer');
print &ui_table_row('Installed version', &html_escape($installed_version || 'Not detected'));
print &ui_table_row('Executable', &html_escape($binary || 'Not found'));
print &ui_table_row('Status', $version_ok ? 'Compatible' : '<strong style="color:#b00">'.&html_escape($version_error).'</strong>');
print &ui_table_end();
print &ui_table_start('Available GoAccess reports', undef, 2);
if (!@ds) {
    print &ui_table_row('Domains', 'No enabled or accessible GoAccess domains found');
}
for my $domain (@ds) {
    my $name = $domain->{'dom'};
    my $safe = &html_escape($name);
    my $url = 'report.cgi?dom='.&ga_urlencode($name);
    my $detail = 'index.cgi?dom='.&ga_urlencode($name);
    my (undef, $report) = ga_paths($domain);
    my $status = -s "$report/index.html" ? 'Report available' : 'Report not yet generated';
    print &ui_table_row($safe,
        '<a href="'.&html_escape($detail).'">Details</a> | '.
        '<a target="_blank" rel="noopener noreferrer" href="'.&html_escape($url).'">Open report</a>'.
        ' ('.&html_escape($status).')');
}
print &ui_table_end();

if ($d) {
    my ($base,$report,$db,$passwd) = ga_paths($d);
    my $url = 'report.cgi?dom='.&ga_urlencode($d->{'dom'});
    print &ui_table_start('GoAccess for '.&html_escape($d->{'dom'}), undef, 2);
    print &ui_table_row('Webmin report', '<a target="_blank" rel="noopener noreferrer" href="'.&html_escape($url).'">'.&html_escape($url).'</a>');
    print &ui_table_row('Storage', &html_escape($base));
    print &ui_table_row('Access log', &html_escape(ga_logfile($d) || 'not found'));
    print &ui_table_row('Authentication user', &html_escape($d->{'user'}));
    print &ui_table_row('Authentication', 'Report links inside Webmin use the existing Webmin login; the public Apache URL still requires Basic Auth.');
    print &ui_table_end();
}
print '<hr><div style="font-size:smaller;opacity:.75;margin-top:12px">GoAccess for Virtualmin v1.4.4 &middot; Copyright &copy; 2026 Frank Beckmann / FNH media KG &middot; <a href="about.cgi">Info / Lizenz</a> &middot; <a href="changelog.cgi">Changelog</a></div>';
&ui_print_footer('/', 'Virtualmin');
