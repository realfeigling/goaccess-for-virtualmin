use WebminCore;
&init_config();
&foreign_require("virtual-server");

# Minimum supported GoAccess version for this module's CLI and database options.
sub ga_min_version { return '1.9.3'; }

sub ga_version_status {
    my $min = ga_min_version();
    my @paths = ('/usr/bin/goaccess', '/usr/local/bin/goaccess');
    my $found;
    for my $path (@paths) {
        next unless -f $path && -x $path;
        my $pid = open(my $fh, '-|');
        return (0, undef, undef, "Cannot execute $path: $!") unless defined $pid;
        if (!$pid) {
            open(STDERR, '>', '/dev/null');
            exec { $path } $path, '--version';
            exit 127;
        }
        local $/;
        my $output = <$fh> // '';
        close($fh);
        my $exit = $? >> 8;
        my ($version) = $output =~ /GoAccess[^\r\n]*?\b(v?\d+\.\d+(?:\.\d+)?(?:[.-][A-Za-z0-9]+)?)\b/i;
        ($version) = $output =~ /\b(v?\d+\.\d+(?:\.\d+)?(?:[.-][A-Za-z0-9]+)?)\b/i unless defined $version;
        if ($exit != 0 || !defined $version) {
            $found ||= "Unable to determine GoAccess version at $path";
            next;
        }
        $version =~ s/^v//i;
        my @parts = split /\./, $version;
        my @minimum = split /\./, $min;
        my $compatible = ($version =~ /^\d+\.\d+(?:\.\d+)?$/);
        if ($compatible) {
            for my $i (0..2) {
                my $a = $parts[$i] // 0;
                my $b = $minimum[$i] // 0;
                if ($a > $b) { last; }
                if ($a < $b) { $compatible = 0; last; }
            }
        }
        return ($compatible, $path, $version,
            $compatible ? undef : "GoAccess $version is below minimum $min or is a prerelease");
    }
    return (0, undef, undef, $found || "GoAccess not installed; requires version $min or newer");
}

# Webmin returns 0 (not a hash reference) for unrestricted module ACLs.
# A restricted user must have a domain explicitly assigned or own it.
sub ga_acl_context {
    my $acl = &get_module_acl();
    my $remote = $ENV{'REMOTE_USER'} || $ENV{'USER'} || '';
    my $is_master = ($remote eq 'root' || $remote eq 'admin') &&
        (ref($acl) ne 'HASH' || !defined($acl->{'doms'}) || $acl->{'doms'} eq '');
    my %allowed;
    if (ref($acl) eq 'HASH') {
        %allowed = map { $_ => 1 } grep { length($_) }
            split(/\s+/, $acl->{'doms'} || '');
    }
    return ($remote, $is_master, \%allowed);
}

sub ga_domain_accessible {
    my ($domain, $remote, $is_master, $allowed) = @_;
    return 0 unless $domain->{'virtualmin-goaccess'};
    return $is_master || $allowed->{$domain->{'dom'}} ||
        (length($remote) && defined($domain->{'user'}) && $domain->{'user'} eq $remote);
}

sub ga_paths {
    my ($d) = @_;
    my $home = $d->{'home'} || "/home/$d->{'user'}";
    my $base = "$home/goaccess";
    # Separate GoAccess password file, but generated from the Virtualmin
    # administration account credentials. This keeps GoAccess independent
    # from whether AWStats is enabled.
    return ($base, "$base/report", "$base/db", "$d->{'home'}/.goaccess-htpasswd");
}

sub ga_url_path {
    my $p = $config{'url_path'} || '/goaccess/';
    $p = "/$p" unless $p =~ m!^/!;
    $p .= "/" unless $p =~ m!/$!;
    return $p;
}

# Create/update the Apache password file using Virtualmin's own helper.
# This uses the Virtualmin administration user and administration password,
# just like the AWStats plugin does, without depending on AWStats itself.
sub ga_ensure_auth {
    my ($d, $olduser) = @_;
    my (undef, undef, undef, $passwd) = ga_paths($d);
    eval {
        &virtual_server::update_create_htpasswd($d, $passwd,
            defined($olduser) ? $olduser : $d->{'user'});
    };
    return (0, $@) if $@;
    return (0, "Virtualmin did not create $passwd") if !-s $passwd;
    chmod(0640, $passwd);
    return (1, undef);
}

sub ga_logfile {
    my ($d) = @_;
    # Virtualmin administration username determines the per-domain home.
    # Prefer Virtualmin's actual home directory (also handles custom homes).
    my $home = $d->{'home'} || "/home/$d->{'user'}";
    my $log = "$home/logs/access_log";
    return $log if -f $log && -r $log;
    return undef;
}

sub ga_ports {
    my ($d) = @_;
    my @p = ($d->{'web_port'} || 80);
    push(@p, ($d->{'web_sslport'} || 443)) if $d->{'ssl'};
    my %seen;
    return grep { !$seen{$_}++ } @p;
}

sub ga_directory_struct {
    my ($d, $report, $passwd) = @_;
    return {
        'name' => 'Directory', 'type' => 1,
        'value' => $report.'/', 'words' => [ $report.'/' ],
        'members' => [
            { 'name'=>'Options', 'value'=>'-Indexes' },
            { 'name'=>'AllowOverride', 'value'=>'None' },
            { 'name'=>'DirectoryIndex', 'value'=>'index.html' },
            { 'name'=>'AuthType', 'value'=>'Basic' },
            { 'name'=>'AuthName', 'value'=>'"'.$d->{'dom'}.' statistics"' },
            { 'name'=>'AuthUserFile', 'value'=>$passwd },
            { 'name'=>'Require', 'value'=>'valid-user' },
        ],
    };
}

sub ga_write_apache {
    my ($d) = @_;
    &virtual_server::require_apache();
    my (undef,$report,undef,$passwd) = ga_paths($d);
    my $url = ga_url_path();
    my $conf = &apache::get_config();
    my $found = 0;

    foreach my $port (ga_ports($d)) {
        my ($virt, $vconf) = &virtual_server::get_apache_virtual($d->{'dom'}, $port);
        next if !$virt || !$vconf;
        $found++;

        my @aliases = &apache::find_directive("Alias", $vconf);
        @aliases = grep { $_ !~ /^\Q$url\E(?:\s|$)/ } @aliases;
        push(@aliases, "$url $report/");
        &apache::save_directive("Alias", \@aliases, $vconf, $conf);

        foreach my $dir (&apache::find_directive_struct("Directory", $vconf)) {
            my $path = $dir->{'words'}->[0] || $dir->{'value'} || '';
            if ($path eq $report || $path eq $report.'/') {
                &apache::save_directive_struct($dir, undef, $vconf, $conf);
            }
        }
        my $ds = ga_directory_struct($d, $report, $passwd);
        &apache::save_directive_struct(undef, $ds, $vconf, $conf);
        &flush_file_lines($virt->{'file'});
        undef(@apache::get_config_cache);
    }
    return (0, "Apache VirtualHost for $d->{'dom'} not found") if !$found;

    my $out = `apache2ctl configtest 2>&1`;
    return (0, $out || 'apache2ctl configtest failed') if $? != 0;
    &virtual_server::register_post_action(\&virtual_server::restart_apache);
    return (1, undef);
}

sub ga_remove_apache {
    my ($d) = @_;
    &virtual_server::require_apache();
    my (undef,$report) = ga_paths($d);
    my $url = ga_url_path();
    my $conf = &apache::get_config();
    my $changed = 0;

    foreach my $port (ga_ports($d)) {
        my ($virt, $vconf) = &virtual_server::get_apache_virtual($d->{'dom'}, $port);
        next if !$virt || !$vconf;
        my $vchanged = 0;
        my @aliases = &apache::find_directive("Alias", $vconf);
        my @keep = grep { $_ !~ /^\Q$url\E(?:\s|$)/ } @aliases;
        if (@keep != @aliases) {
            &apache::save_directive("Alias", \@keep, $vconf, $conf);
            $vchanged++;
        }
        foreach my $dir (&apache::find_directive_struct("Directory", $vconf)) {
            my $path = $dir->{'words'}->[0] || $dir->{'value'} || '';
            if ($path eq $report || $path eq $report.'/') {
                &apache::save_directive_struct($dir, undef, $vconf, $conf);
                $vchanged++;
            }
        }
        if ($vchanged) {
            &flush_file_lines($virt->{'file'});
            undef(@apache::get_config_cache);
            $changed += $vchanged;
        }
    }
    &virtual_server::register_post_action(\&virtual_server::restart_apache) if $changed;
    return 1;
}

# GoAccess uses its persisted DB for incremental imports. Track the exact
# number of bytes already processed; a changed inode or truncated log causes
# a complete rebuild from the available rotated history.
# Add the Virtualmin domain to the generated standalone GoAccess HTML report.
# Escape all domain-derived text and replace the report atomically.
sub ga_label_report {
    my ($path, $domain) = @_;
    return 0 unless defined($domain) && length($domain) && -f $path;
    open(my $in, '<', $path) or return 0;
    binmode($in);
    local $/;
    my $html = <$in>;
    close($in);
    return 0 unless defined($html) && $html =~ /<body\b/i;

    my $label = $domain;
    $label =~ s/&/&amp;/g;
    $label =~ s/</&lt;/g;
    $label =~ s/>/&gt;/g;
    $label =~ s/"/&quot;/g;
    $label =~ s/'/&#39;/g;

    # Keep repeated processing idempotent (e.g. when a report is rebuilt).
    $html =~ s{<!-- virtualmin-goaccess-domain:start -->.*?<!-- virtualmin-goaccess-domain:end -->}{}sg;
    my $banner = '<!-- virtualmin-goaccess-domain:start -->'
        . '<div id="virtualmin-goaccess-domain" style="box-sizing:border-box;'
        . 'padding:14px 22px;background:#202b38;color:#fff;'
        . 'font:600 20px/1.4 Arial,Helvetica,sans-serif;">'
        . 'GoAccess &ndash; ' . $label . '</div>'
        . '<!-- virtualmin-goaccess-domain:end -->';
    $html =~ s{(<body\b[^>]*>)}{$1\n$banner}i or return 0;
    if ($html =~ /<title\b[^>]*>.*?<\/title>/is) {
        $html =~ s{<title\b[^>]*>.*?<\/title>}{<title>GoAccess - $label</title>}is;
    } else {
        $html =~ s{</head>}{<title>GoAccess - $label</title>\n</head>}i;
    }

    my $tmp = "$path.$$";
    open(my $out, '>', $tmp) or return 0;
    binmode($out);
    my $written = print {$out} $html;
    my $closed = close($out);
    unless ($written && $closed) {
        unlink($tmp);
        return 0;
    }
    unless (rename($tmp, $path)) { unlink($tmp); return 0; }
    return 1;
}

sub ga_generate {
    my ($d, $initial) = @_;
    require Fcntl;
    require File::Path;
    require IO::Handle;
    my ($base,$report,$db) = ga_paths($d);
    my $log = ga_logfile($d);
    return 0 unless $log && -r $log;
    my ($supported, $goaccess, $installed, $version_error) = ga_version_status();
    unless ($supported) { warn "$version_error\n"; return 0; }
    File::Path::make_path($base, $report, $db);
    my $lockfile = "$base/.update.lock";
    open(my $lock, '>>', $lockfile) or return 0;
    flock($lock, 2) or return 0;

    my @st = stat($log);
    return 0 unless @st;
    my ($dev,$inode,$size) = @st[0,1,7];
    my $statefile = "$base/.import-state";
    my ($olddev,$oldinode,$oldoffset);
    if (open(my $sf, '<', $statefile)) {
        my $line = <$sf> // '';
        ($olddev,$oldinode,$oldoffset) = $line =~ /^(\d+) (\d+) (\d+)$/;
        close($sf);
    }
    my $db_exists = -d $db && scalar(glob("$db/*"));
    my $rebuild = $initial || !$db_exists || !defined($oldoffset) ||
                  $olddev != $dev || $oldinode != $inode || $size < $oldoffset;
    if (!$rebuild && $size == $oldoffset && -s "$report/index.html") {
        # Apply the domain banner to existing reports after upgrading, even
        # when there have been no new access-log entries.
        open(my $existing, '<', "$report/index.html") or return 0;
        local $/;
        my $html = <$existing> // '';
        close($existing);
        if ($html !~ /<!-- virtualmin-goaccess-domain:start -->/) {
            return 0 unless ga_label_report("$report/index.html", $d->{'dom'});
            my @pw = getpwnam($d->{'user'});
            my $gid = getgrnam($d->{'group'} || $d->{'user'});
            chown($pw[2], $gid, "$report/index.html") if @pw && defined($gid);
            chmod(0640, "$report/index.html");
        }
        print "GoAccess: no new log data for $d->{'dom'}; report current\n";
        return 1;
    }

    my @archives;
    if ($rebuild) {
        my $dir = $log;
        $dir =~ s!/access_log$!!;
        opendir(my $dh, $dir) or return 0;
        @archives = map { "$dir/access_log.$_.gz" }
                    sort { $b <=> $a }
                    map { /^access_log\.(\d+)\.gz$/ ? $1 : () }
                    readdir($dh);
        closedir($dh);
        # Remove old checkpoint first: any failed rebuild must retry from scratch.
        unlink($statefile);
        File::Path::remove_tree($db);
        File::Path::make_path($db);
    }

    my $fmt = $config{'log_format'} || 'COMBINED';
    return 0 unless $fmt =~ /^[A-Za-z0-9_:% .\-]+$/;
    my @cmd = ($goaccess, '-', '--log-format='.$fmt,
               '--db-path='.$db, '--persist', '--no-progress',
               '--output='.$report.'/index.html');
    push @cmd, '--restore' unless $rebuild;
    my $pid = open(my $pipe, '|-');
    return 0 unless defined $pid;
    if ($pid == 0) {
        local $ENV{'LC_TIME'} = 'C';
        exec { $cmd[0] } @cmd;
        exit 127;
    }
    binmode($pipe);
    my $ok = 1;
    if ($rebuild) {
        for my $archive (@archives) {
            my $zpid = open(my $z, '-|', '/bin/gzip', '-cd', '--', $archive);
            if (!defined $zpid) { $ok = 0; last; }
            binmode($z);
            while (read($z, my $buf, 65536)) {
                if (!print {$pipe} $buf) { $ok = 0; last; }
            }
            close($z) or $ok = 0;
            last unless $ok;
        }
    }
    if ($ok) {
        if (open(my $src, '<', $log)) {
            binmode($src);
            seek($src, $rebuild ? 0 : $oldoffset, 0) or $ok = 0;
            my $remaining = $size - ($rebuild ? 0 : $oldoffset);
            while ($ok && $remaining > 0) {
                my $n = read($src, my $buf, $remaining > 65536 ? 65536 : $remaining);
                if (!defined($n) || $n == 0) { $ok = 0; last; }
                $remaining -= $n;
                $ok = 0 unless print {$pipe} $buf;
            }
            close($src);
        } else { $ok = 0; }
    }
    close($pipe) or $ok = 0;
    warn "GoAccess report generation failed for $d->{'dom'}\n" unless $ok;
    return 0 unless $ok && -s "$report/index.html";
    unless (ga_label_report("$report/index.html", $d->{'dom'})) {
        warn "Cannot add domain label to GoAccess report for $d->{'dom'}\n";
        return 0;
    }
    my $tmp = "$statefile.$$";
    open(my $sf, '>', $tmp) or return 0;
    print {$sf} "$dev $inode $size\n";
    close($sf) or return 0;
    rename($tmp, $statefile) or return 0;
    my @pw = getpwnam($d->{'user'});
    my $gid = getgrnam($d->{'group'} || $d->{'user'});
    if (@pw && defined($gid)) {
        chown($pw[2], $gid, "$report/index.html", $statefile);
    }
    chmod(0640, "$report/index.html", $statefile);
    return 1;
}

1;
