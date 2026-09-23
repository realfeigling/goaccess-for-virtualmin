#!/usr/bin/perl
use warnings;
no warnings 'once';
BEGIN {
    $ENV{WEBMIN_CONFIG} ||= '/etc/webmin';
    $ENV{WEBMIN_VAR} ||= '/var/webmin';
    unshift @INC, '/usr/share/webmin';
}
require '/usr/share/webmin/virtualmin-goaccess/virtualmin-goaccess-lib.pl';
require Fcntl;
my $lockpath = '/var/webmin/virtualmin-goaccess-scheduler.lock';
open(my $lock, '>>', $lockpath) or die "Cannot open $lockpath: $!\n";
flock($lock, 2 | 4) or exit 0; # Avoid concurrent runs
my $interval = $config{'update_minutes'} || 5;
die "Invalid interval\n" unless $interval =~ /^\d+$/ && $interval >= 1 && $interval <= 10080;
# Exact cron schedules do not need the additional elapsed-time guard.
# Other intervals (e.g. 90 minutes or 7 days) retain timestamp gating.
my $cron_exact =
    ($interval < 60 && 60 % $interval == 0)
    || $interval == 60
    || ($interval > 60 && $interval % 60 == 0 && 1440 % $interval == 0);
my $stamp = '/var/webmin/virtualmin-goaccess-last-run';
if (!$cron_exact && !grep { $_ eq '--force' } @ARGV && -f $stamp) {
    my $last = (stat($stamp))[9];
    if (defined($last) && time - $last < $interval * 60) {
        exit 0;
    }
}
my @ds = &virtual_server::list_domains();
my ($failed, $total) = (0, 0);
for my $d (@ds) {
    next unless $d->{'virtualmin-goaccess'};
    ++$total;
    unless (ga_generate($d, 0)) {
        warn "GoAccess failed for $d->{'dom'} ($d->{'user'})\n";
        ++$failed;
    }
}
if (!$failed) {
    open(my $out, '>', $stamp) or die "Cannot write $stamp: $!\n";
    print {$out} time, "\n";
    close($out);
}
print "GoAccess: $total domain(s), $failed failed\n";
exit($failed ? 1 : 0);
