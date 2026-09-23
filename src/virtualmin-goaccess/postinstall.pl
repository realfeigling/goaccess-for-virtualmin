#!/usr/bin/perl
# Webmin calls module_install after installation and upgrades.
use strict;
use warnings;
sub module_install {
    my $binary = -x "/usr/bin/goaccess" ? "/usr/bin/goaccess" : "/usr/local/bin/goaccess";
    if (!-x $binary) {
        warn "GoAccess not found: install version 1.9.3 or newer before enabling the feature\n";
    }
    my $installer = '/usr/share/webmin/virtualmin-goaccess/install-cron.sh';
    if ($> != 0) {
        warn "GoAccess: cron installation requires root; run $installer\n";
    }
    elsif (system('/bin/sh', $installer) != 0) {
        warn "GoAccess: cron installation failed; run $installer and check /etc/cron.d\n";
    }
}
1;
