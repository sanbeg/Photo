#! /usr/bin/perl -w

use FindBin;
use lib $FindBin::Bin;
use DirLog;
use Data::Dumper;
use Getopt::Long;

my $other;
my $dir;

GetOptions ( 'log=s' => \$other, 'directory=s' => \$dir ) or die;

die "-log is required" unless defined $other;
die "-dir is required" unless defined $dir;

my $other_log = DirLog->from_file($other);
my $log = DirLog->new($dir);

$log->sync_dir_to_file($dir, $other_log);
$log->write($dir);
