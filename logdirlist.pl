#! /usr/bin/perl -w

use FindBin;
use lib $FindBin::Bin;
use DirLog;

foreach my $dir (@ARGV) {
  my $log = DirLog->new($dir);
  $log->write($dir);
}

