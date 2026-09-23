do 'virtualmin-goaccess-lib.pl';

sub feature_name { return "GoAccess Web Statistics"; }
sub feature_label { return "GoAccess Web Statistics"; }
sub feature_check {
    my ($ok, undef, undef, $reason) = ga_version_status();
    return $reason unless $ok;
    return "apache2ctl is not installed" if !&has_command("apache2ctl");
    return undef;
}
sub feature_depends { my ($d)=@_; return $d->{'web'} ? undef : "GoAccess requires the Website feature"; }
sub feature_suitable { my ($parent,$alias,$super)=@_; return ($alias || $super) ? 0 : 1; }
sub feature_losing { return "GoAccess statistics, database and protected web endpoint will be removed"; }

sub feature_setup {
    my ($d)=@_;
    &$virtual_server::first_print("Setting up GoAccess Web Statistics ..");
    my ($base,$report,$db,$passwd)=ga_paths($d);
    for my $dir ($base,$report,$db) { &make_dir($dir, 0750, 1); }
    my @pw = getpwnam($d->{'user'});
    my $gid = getgrnam($d->{'group'} || $d->{'user'});
    if (@pw && defined($gid)) { chown($pw[2], $gid, $base, $report, $db); }

    my ($auth_ok,$auth_err)=ga_ensure_auth($d);
    if (!$auth_ok) { &$virtual_server::second_print(".. authentication setup failed: $auth_err"); return 0; }

    my ($ok,$err)=ga_write_apache($d);
    if (!$ok) { &$virtual_server::second_print(".. Apache configuration failed: $err"); return 0; }
    ga_generate($d, 1);
    &$virtual_server::second_print(".. done - authentication uses Virtualmin administration user $d->{'user'}");
    return 1;
}

sub feature_delete {
    my ($d)=@_;
    &$virtual_server::first_print("Removing GoAccess Web Statistics ..");
    ga_remove_apache($d);
    my ($base,undef,undef,$passwd)=ga_paths($d);
    system('rm', '-rf', '--', $base);
    unlink($passwd) if -e $passwd;
    &$virtual_server::second_print(".. done");
    return 1;
}

sub feature_modify {
    my ($d,$old)=@_;
    my $changed = 0;

    if ($d->{'dom'} ne $old->{'dom'} || $d->{'home'} ne $old->{'home'} ||
        ($d->{'web_port'}||80) != ($old->{'web_port'}||80) ||
        ($d->{'web_sslport'}||443) != ($old->{'web_sslport'}||443) ||
        ($d->{'ssl'}||0) != ($old->{'ssl'}||0)) {
        &$virtual_server::first_print("Updating GoAccess configuration ..");
        ga_remove_apache($old);
        if ($d->{'home'} ne $old->{'home'} && -d "$old->{'home'}/goaccess") {
            rename("$old->{'home'}/goaccess", "$d->{'home'}/goaccess");
        }
        my (undef,undef,undef,$oldpass)=ga_paths($old);
        my (undef,undef,undef,$newpass)=ga_paths($d);
        if ($oldpass ne $newpass && -e $oldpass) { rename($oldpass, $newpass); }
        my ($ok,$err)=ga_write_apache($d);
        if (!$ok) { &$virtual_server::second_print(".. failed: $err"); return 0; }
        &$virtual_server::second_print(".. done");
        $changed++;
    }

    # Keep Basic Auth synchronized with the Virtualmin administration account,
    # exactly as Virtualmin's AWStats feature does.
    if ($d->{'user'} ne $old->{'user'} ||
        (defined($d->{'pass'}) && (!defined($old->{'pass'}) || $d->{'pass'} ne $old->{'pass'})) ||
        (defined($d->{'enc_pass'}) && (!defined($old->{'enc_pass'}) || $d->{'enc_pass'} ne $old->{'enc_pass'}))) {
        &$virtual_server::first_print("Updating GoAccess administration credentials ..");
        my ($ok,$err)=ga_ensure_auth($d, $old->{'user'});
        if (!$ok) { &$virtual_server::second_print(".. failed: $err"); return 0; }
        &$virtual_server::second_print(".. done");
        $changed++;
    }
    return 1;
}

sub feature_disable { my ($d)=@_; &$virtual_server::first_print("Disabling GoAccess Web Statistics .."); ga_remove_apache($d); &$virtual_server::second_print(".. done"); return 1; }
sub feature_enable { my ($d)=@_; &$virtual_server::first_print("Enabling GoAccess Web Statistics .."); my ($aok,$aerr)=ga_ensure_auth($d); if (!$aok) { &$virtual_server::second_print(".. failed: $aerr"); return 0; } my ($ok,$err)=ga_write_apache($d); &$virtual_server::second_print($ok ? ".. done" : ".. failed: $err"); return $ok; }
sub feature_validate {
    my ($d)=@_; my ($base,$report,$db,$passwd)=ga_paths($d);
    return "Missing GoAccess report directory $report" if !-d $report;
    return "Missing GoAccess database directory $db" if !-d $db;
    return "Missing or empty GoAccess authentication file $passwd" if !-s $passwd;
    return "No readable Apache CustomLog found for $d->{'dom'}" if !ga_logfile($d);
    return undef;
}
sub feature_webmin {
    my ($d,$all)=@_;
    my @doms = map { $_->{'dom'} } grep { $_->{'virtualmin-goaccess'} } @$all;
    push(@doms, $d->{'dom'}) if !grep { $_ eq $d->{'dom'} } @doms;
    return ( [ $module_name, { 'doms' => join(' ', @doms) } ] );
}
sub feature_links { my ($d)=@_; return ({ 'mod'=>$module_name, 'desc'=>'GoAccess Web Statistics', 'page'=>'index.cgi?dom='.$d->{'dom'}, 'cat'=>'logs' }); }
sub settings_links { return ({ 'link'=>"/$module_name/edit_config.cgi", 'title'=>'GoAccess Configuration', 'for_master'=>1 }); }
1;
