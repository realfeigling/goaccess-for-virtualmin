#!/usr/bin/perl
require './virtualmin-goaccess-lib.pl'; &ReadParse();
&error('Invalid URL path') if $in{'url_path'} !~ m!^/[A-Za-z0-9_.-]+/$!;
&error('Invalid interval') if $in{'update_minutes'} !~ /^\d+$/ || $in{'update_minutes'} < 1 || $in{'update_minutes'} > 10080;
&error('Invalid GoAccess log format') unless grep { $_ eq ($in{'log_format'} // '') }
    qw(COMBINED COMMON VCOMBINED CLOUDFRONT CLOUDSTORAGE AWSELB SQUID W3C);
my $previous_interval = $config{'update_minutes'} || 5;
$config{'url_path'}=$in{'url_path'}; $config{'update_minutes'}=$in{'update_minutes'}; $config{'log_format'}=$in{'log_format'};
&save_module_config();
# Reconcile cron automatically after changing module settings.
if ($> == 0) {
    my $rc = system('/bin/sh', '/usr/share/webmin/virtualmin-goaccess/install-cron.sh');
    &error('Settings saved, but automatic cron setup failed') if $rc != 0;
    # Apply a changed interval at the next minute rather than waiting on
    # the timestamp from the previous interval.
    unlink('/var/webmin/virtualmin-goaccess-last-run')
        if $previous_interval != $in{'update_minutes'};
}
&redirect('edit_config.cgi');
