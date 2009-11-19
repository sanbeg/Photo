#! /usr/bin/perl -w

use strict;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin";
use lib "$FindBin::Bin/../perl";
use CPPic;

my $freshen;
#unimplemented
my ($from,$to);
my $rotate=1;
my $move;

GetOptions(
    'from=i'=>\$from, 'to=i'=>\$to, 'rotate!'=>\$rotate, 
    'freshen:s'=>\$freshen, 'move!'=>\$move, 
    'test!'=>\$CPPic::test, 'verbose+'=>\$CPPic::verbose,
    'prefix=s'=>\$CPPic::prefix,
    );

umask 033;

my $dst = shift;
die "Copy to where?" unless defined $dst;
die "too many args" if @ARGV;

my $do_fresh=1;
unless (-d $dst) {
    mkdir $dst or die "$dst: $!";
    $do_fresh=0;
};


my $pic = CPPic->new;

$pic->find_cameras;
$pic->init_src;

print "$_\n" for @{$pic->{folders}};

if (defined $from) {
    $pic->freshen($dst, $from);
} elsif (defined $freshen) {
    my $refresh = ($freshen eq '') ? $dst : $freshen;
    warn "Freshening $refresh";
    $pic->freshen( $refresh ) 
} elsif ($do_fresh) {
    $pic->freshen( $dst );
}

$pic->copy_all($dst);
$pic->rotate if $rotate;
