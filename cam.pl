#! /usr/bin/perl -w

use strict;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin";
use lib "$FindBin::Bin/../perl";
use CPPic;
use DetectRoll;

my $pic = CPPic->new;
$pic->find_cameras;
$pic->init_src;

my %shutter_count;
my %filenum;
my %dirnum;
foreach my $dir (@{$pic->{folders}}) {
    print "$dir\n";
    $dir =~ m:.+/([0-9]+): and do {
	my $dirn=$1;
	print "$dirn\n";
	opendir DH, $dir or die "$dir: $!";
	while (my $fn = readdir DH) {
	    if ($fn =~ m/(?:$CPPic::prefix).*?([0-9]+)/i) {
		$filenum{$dirn} = $1;
		$dirnum{$dirn} = $dir;
		last;
	    }
	}
	closedir DH;
    }
}

my $max_fn=0;
my $roll;
foreach my $dirn (sort {$a <=> $b} keys %filenum) {
    my $fn = $filenum{$dirn};
    warn "$dirn $fn $max_fn";
    if ($fn < $max_fn) {
	warn "camera rolled @ $dirn";
	$roll=$dirn;
    };
    $max_fn = $fn;
}

if (defined $roll) {
    my @dirs;
    while (my ($num,$name) = each %dirnum) {
	push @dirs, $name if $num >= $roll;
    }
    my ($min_r, $max_r) = (9999,0);
    foreach my $dir (@dirs) {
	warn $dir;
	opendir DH, $dir or die "$dir: $!";
	while (my $fn = readdir DH) {
	    if ($fn =~ m/(?:$CPPic::prefix).*?([0-9]+)/i) {
		my $n = $1;
		$min_r = $n if $n < $min_r;
		$max_r = $n if $n > $max_r;
	    }
	}
	closedir DH;
    }
    print "$min_r $max_r $roll\n";
# if last photo on computer > $max_r - refresh before $roll
# then always refresh after roll.

    if (my $dir = shift) {
	$pic->freshen($dir);


	my $dr=DetectRoll->new($dir);
	my $has_roll=$dr->has_roll;
	print "dir rollover:", $has_roll ? "yes\n" : "no\n";
	my ($left,$right) = $dr->find_roll;

	if ($has_roll) {
	    print "\tlast image is $left; earliest is $right\n";
	    print "refresh old\n" if $left > $max_r;
	} else {
	    print $pic->{from}, "\n";
	    print "refresh old\n" if $pic->{from}-1 > $max_r;
	}
    }
}

