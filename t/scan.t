#! /usr/bin/perl

use Test::More;
use lib '.';
use lib '../Test-Directory/lib';
use Test::Directory;

my $d="tmp";

my $src=Test::Directory->new;
my $dst=Test::Directory->new;

my $d_src = $src->path;
my $d_dst = $dst->path;

$src->touch(1, 2, 3);
$dst->touch(4);

ok (!system("./scan.pl -log $d_src $d_dst"), "run scan");

$dst->has($_, "File was copied: $_") for 1,2,3;

$dst->hasnt(4, "File was removed");
#ok ($src->has('dir.log'), "src has log");
$dst->has('.dirlog', "dst has log");

unlink($dst->path(3));

#.dirlog seems to be copied from src if nothing changes?
ok (!system("./scan.pl -log $d_src $d_dst"), "run scan again");
# ok (!system("./scan.pl -log $d/src $d/dst"), "run scan again");
# ok (!system("./scan.pl -log $d/src $d/dst"), "run scan again");
$dst->hasnt(3, "removed file not replaced");
# $dst->clean(Test::More->builder->is_passing);
#$dst->clean(0);

done_testing();
