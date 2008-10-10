#! /usr/bin/perl -w

use strict;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin";
use CPPic;

my $freshen;
#unimplemented
my ($from,$to);
my $rotate=1;
my $move;

GetOptions('from=i'=>\$from, 'to=i'=>\$to, 'rotate!'=>\$rotate, 
	   'freshen:s'=>\$freshen, 'move!'=>\$move, 
	   'test!'=>\$CPPic::test, 'verbose+'=>\$CPPic::verbose);

umask 033;

my $dst = shift;
die "Copy to where?" unless defined $dst;
die "too many args" if @ARGV;

my $pic = CPPic->new;

$pic->find_cameras;

print "$_\n" for @{$pic->{folders}};

if (defined $from) {
    $pic->freshen($dst, $from);
} elsif (defined $freshen) {
    $pic->freshen( ($freshen eq '') ? $dst : $freshen ) 
}

$pic->copy_all($dst);
$pic->rotate if $rotate;
