#!/usr/bin/perl
require './virtualmin-goaccess-lib.pl';
&ui_print_header(undef,'GoAccess Configuration','',undef,1,1);
print &ui_form_start('save_config.cgi');
print &ui_table_start('Global settings',undef,2);
print &ui_table_row('URL path', &ui_textbox('url_path',$config{'url_path'} || '/goaccess/',40));
print &ui_table_row('Update interval (minutes)', &ui_textbox('update_minutes',$config{'update_minutes'} || 5,10));
print &ui_table_row('GoAccess log format', &ui_select('log_format', $config{'log_format'} || 'COMBINED', [
    map { [ $_, $_ ] } qw(COMBINED COMMON VCOMBINED CLOUDFRONT CLOUDSTORAGE AWSELB SQUID W3C)
]));
print &ui_table_end(); print &ui_form_end([ [undef,'Save'] ]); &ui_print_footer('/','Virtualmin');
