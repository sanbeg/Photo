#! /usr/bin/perl -w

use FindBin;
use lib $FindBin::Bin;
use DirLog;
use Data::Dumper;

my $other = shift;
my $other_log = DirLog->from_file($other);
my $log = DirLog->new('.');

$log->sync_dir_to_file('.', $other_log);
