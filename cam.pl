#! /usr/bin/perl -w

use strict;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin";
use lib "$FindBin::Bin/../perl";
use CPPic;
use DetectRoll;
use CamRoll;

my $pic = CPPic->new;
$pic->find_cameras;
$pic->init_src;

my ($roll,$max_r) = CamRoll::find($pic);

# if last photo on computer > $max_r - refresh before $roll
# then always refresh after roll.
if (defined $roll) {
    if (my $dir = shift) {
	$pic->freshen($dir);


	my $dr=DetectRoll->new($dir);
	my $has_roll=$dr->has_roll;
	print "dir rollover:", $has_roll ? "yes\n" : "no\n";
	my ($left,$right) = $dr->find_roll;

	if ($has_roll) {
	    print "\tlast image is $left; earliest is $right\n";
	    print "refresh old\n" if $left > $max_r; #should never happen?
	} else {
	    print $pic->{from}, "\n";
	    print "refresh old\n" if $pic->{from}-1 > $max_r;
	}
    }

    print "start at $roll / $max_r\n";
}

