#! /usr/bin/perl -w

use strict;
use Getopt::Long;
use Image::ExifTool ':Public';

#MaxApertureValue & EffectiveMaxAperture both seem to give max,
#with some rounding error.

my %opt;
GetOptions (\%opt, 'verbose!', 'summary!', 'lens=s') or die;


my @tags=('Lens', 'FocalLength');
my $type='ValueConv';
my %lenscount;

my $exiftool = Image::ExifTool->new;
$exiftool->Options(FastScan=>1);
$exiftool->Options(Composite=>0); #def ShutterSpeed is a composite

#foreach my $image (@ARGV){
while (my $image = <>) {
    chomp $image;
    my $info = $exiftool->ExtractInfo($image);
    my $lens;
    foreach my $tag (@tags) {
	my $val = $exiftool->GetValue($tag,$type);

	unless (defined $val) {
	    #warn "no lens for $image";
	    next;
	}
	if ($tag eq 'Lens') {
	    my @lens = split ' ', $val;
	    if ($lens[0] eq $lens[1]) {
		$val = $lens[0];
	    } else {
		$val = "$lens[0]-$lens[1]";
	    }
	    $val .= " f/";
	    if ($lens[2] eq $lens[3]) {
		$val .= $lens[2];
	    } else {
		$val .= "$lens[2]-$lens[3]";
	    }
	    $lenscount{$val} ++;
	    $lens = $val;
	}
	elsif ($tag eq 'FocalLength' and 
	       !defined($opt{lens}) or $lens eq $opt{lens}) {
	    print "$lens\t$val\n";
	}
    }
}

if ($opt{summary}){
    while (my ($lens, $count) = each %lenscount) {
	print "$lens\t$count\n";
    }
}
