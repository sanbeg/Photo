#! /usr/bin/perl

use Test::More;
use lib '.';
use TestDir;

my $d="tmp";

my $src=TestDir->new("$d/src");
my $dst=TestDir->new("$d/dst");

$src->touch(1, 2, 3);
$dst->touch(4);

ok (!system("./scan.pl -log $d/src $d/dst"), "run scan");

ok (-f $dst->path($_), "File was copied: $_") for 1,2,3;
ok ($dst->has($_), "File was copied: $_") for 1,2,3;
ok (!$dst->has(4), "File was removed");
#ok ($src->has('dir.log'), "src has log");
ok ($dst->has('.dirlog'), "dst has log");

unlink($dst->path(3));

#.dirlog seems to be copied from src if nothing changes?
ok (!system("./scan.pl -log $d/src $d/dst"), "run scan again");
# ok (!system("./scan.pl -log $d/src $d/dst"), "run scan again");
# ok (!system("./scan.pl -log $d/src $d/dst"), "run scan again");
ok(!$dst->has(3), "removed file not replaced");
# $dst->clean(Test::More->builder->is_passing);
#$dst->clean(0);

done_testing();
