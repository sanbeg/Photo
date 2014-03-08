#! /usr/bin/perl -w

use FindBin;
use Getopt::Long;
use lib $FindBin::Bin;
use DirLog;

my %mod_opts;
my %script_opts;

GetOptions(\%script_opts, 'add') or die;
$mod_opts{state} = 'A' if $script_opts{add};

foreach my $dir (@ARGV) {
  my $log = DirLog->new($dir, \%mod_opts);
  $log->write($dir);
}

