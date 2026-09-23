#!/usr/bin/perl
# Serve a domain's GoAccess HTML only after checking the current Webmin ACL.
use strict;
no strict "vars"; # WebminCore exports %in and module globals
use warnings;
no warnings "once";
use Fcntl qw(O_RDONLY O_NOFOLLOW);
use File::Basename qw(dirname);
require './virtualmin-goaccess-lib.pl';
&ReadParse();

sub deny {
    my ($status, $message) = @_;
    print "Status: $status\nContent-Type: text/plain; charset=UTF-8\nCache-Control: no-store\n\n$message\n";
    exit;
}

my $selected = $in{'dom'} || '';
deny('400 Bad Request', 'Missing or invalid domain')
    unless $selected =~ /\A[A-Za-z0-9][A-Za-z0-9_.-]{0,252}\z/;

# Never accept an arbitrary path from the request. Only a Virtualmin domain
# enabled for this feature can select the fixed report/index.html file.
my ($remote, $is_master, $allowed) = ga_acl_context();
my ($domain) = grep {
    $_->{'dom'} eq $selected &&
    ga_domain_accessible($_, $remote, $is_master, $allowed)
} &virtual_server::list_domains();
deny('403 Forbidden', 'Domain not accessible') unless $domain;

my (undef, $report) = ga_paths($domain);
my $file = "$report/index.html";
# Refuse symlinks, including a replaced report directory, to prevent
# Webmin's privileged CGI from serving an arbitrary filesystem path.
deny('404 Not Found', 'Report not available') if -l $report || -l $file;
my @pw = getpwnam($domain->{'user'});
deny('403 Forbidden', 'Domain account unavailable') unless @pw;
my $flags = O_RDONLY | O_NOFOLLOW;
sysopen(my $fh, $file, $flags) or deny('404 Not Found', 'Report not available');
my @st = stat($fh);
deny('403 Forbidden', 'Invalid report file')
    unless @st && -f $fh && $st[4] == $pw[2];

# Opaque origin: allow GoAccess inline scripts and eval, but no network.
# The previous CSP blocked eval used by some generated GoAccess reports.
# Embedded report scripts may run, but cannot access the
# authenticated Webmin origin or send data to remote endpoints.
print "Content-Type: text/html; charset=UTF-8\n";
print "Cache-Control: no-store\n";
print "X-Content-Type-Options: nosniff\n";
print "Referrer-Policy: no-referrer\n";
print "Content-Security-Policy: sandbox allow-scripts; default-src 'none'; script-src 'unsafe-inline' 'unsafe-eval' data: blob:; style-src 'unsafe-inline' data:; img-src data: blob:; font-src data:; connect-src 'none'; form-action 'none'; base-uri 'none'\n\n";
binmode($fh);
while (read($fh, my $chunk, 65536)) { print $chunk; }
close($fh);
