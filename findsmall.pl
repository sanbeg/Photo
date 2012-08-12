#! /usr/bin/perl

use Image::ExifTool;
use File::Spec;

$exiftool = Image::ExifTool->new;

sub scan_dir( $ ) {
    my $dir = shift;
    opendir my($dh), $dir;
    while (my $file = readdir $dh) {
	next if $file =~ m/^\./;
	if (-d "$dir/$file") {
	    #warn "$dir/$file";
	    scan_dir("$dir/$file");
	}
	elsif ( $file =~ m/\.jpg$/i and -f "$dir/$file" ) {
	    my $size = -s _;
	    #print "$file = $size\n";
	    next unless $size < 500_000;

	    $exiftool->ExtractInfo("$dir/$file", {FastScan=>1});
	    my $info = $exiftool->GetInfo('ImageWidth', 'ImageHeight');
	    next if $info->{ImageHeight} >= $info->{ImageWidth};
	    #print "$info->{ImageHeight} >= $info->{ImageWidth}\n";

	    print "$dir/$file\n";
	    #should also look in other subdirs
	    next unless $file =~ m/([0-9]+)/;
	    my $orig = "dsc_$1.jpg";
	    foreach my $big ($file, $orig) {
		my $big 
		my $bigpath;
		if ( -f "$dir/../$big") {
		    $bigpath = $dir;
		    $bigpath =~ s:/[^/]+$:/$big:
		    #$bigpath =  "$dir/../$big";

		}
		elsif ( $file ne $big and -f "$dir/$big") {
		    $bigpath = "$dir/$big";
		}
		else {
		    for my $other (<$dir/../*/$big>) {
			if (-s $other > 500_000) {
			    $bigpath = $other;
			    last;
			}
		    }
		    
		}
		if (defined $bigpath) {
		    print "  ->$bigpath\n";
		}
	    }
	}
    };
    closedir $dh;
};

scan_dir(shift or '.');

