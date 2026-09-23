# Hook loaded by Webmin's standard module Configuration editor.
# config_save.cgi writes the new module config before calling this hook.
sub config_post_save {
    my ($new, $old) = @_;
    my $interval = $new->{'update_minutes'};
    my $url = $new->{'url_path'} // '';
    my %valid_formats = map { $_ => 1 } qw(COMBINED COMMON VCOMBINED CLOUDFRONT CLOUDSTORAGE AWSELB SQUID W3C);
    my $format = $new->{'log_format'} // '';
    if (!defined($interval) || $interval !~ /\A[0-9]+\z/ ||
        $interval < 1 || $interval > 10080 ||
        $url !~ m!\A/[A-Za-z0-9_.-]+/\z! || !$valid_formats{$format}) {
        &write_file("$config_directory/virtualmin-goaccess/config", $old);
        &error('Invalid GoAccess configuration: interval must be 1..10080 minutes, URL path must be /name/, and log format must be selected from the list');
    }
    if ($> != 0 || system('/bin/sh',
            '/usr/share/webmin/virtualmin-goaccess/install-cron.sh') != 0) {
        &write_file("$config_directory/virtualmin-goaccess/config", $old);
        # Reconcile cron with restored configuration if possible.
        system('/bin/sh', '/usr/share/webmin/virtualmin-goaccess/install-cron.sh') if $> == 0;
        &error('GoAccess configuration reverted: cron update failed (root required)');
    }
    if (($old->{'update_minutes'} // '') ne $interval) {
        unlink('/var/webmin/virtualmin-goaccess-last-run');
    }
}
1;
