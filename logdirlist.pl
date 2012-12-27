#! /usr/bin/perl -w

use FindBin;
use lib $FindBin::Bin;
use DirLog;

my $dir = shift;
my $log = DirLog->new($dir);
$log->write($dir);
