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
		} elsif ( $file =~ m/\.jpg$/i and -f "$dir/$file" ) {
			my $size = -s _;
			#print "$dir/$file = $size\n";
			next unless $size < 500_000;

			$exiftool->ExtractInfo("$dir/$file", {FastScan=>1});
			my $info = $exiftool->GetInfo('ImageWidth', 'ImageHeight');
			next if $info->{ImageHeight} >= $info->{ImageWidth};
			#print "$info->{ImageHeight} >= $info->{ImageWidth}\n";

			print "$dir/$file\n";
			#should also look in other subdirs
			next unless $file =~ m/([0-9]+)/;
			my $orig = "dsc_$1.jpg";
			my $bigpath;
			foreach my $big ($file, $orig) {
				if ( -f "$dir/../$big") {
					$bigpath = $dir;
					$bigpath =~ s:/[^/]+$:/$big:
					#$bigpath =  "$dir/../$big";
				
				} elsif ( $file ne $big and -f "$dir/$big") {
					$bigpath = "$dir/$big";
				} else {
					for my $other (<$dir/../*/$big>) {
						if (-s $other > 500_000) {
							$bigpath = $other;
							last;
						}
					}
				
				}
				last if defined $bigpath;
			}
			if (defined $bigpath) {
				print "  ->$bigpath\n";
				my $out = $bigpath;
				$out =~ s:/:-:g;
				system "convert -resize 800x600^ '$bigpath' '800x/tmp.jpg'";

				$exiftool->ExtractInfo("800x/tmp.jpg", {FastScan=>1});
				my $info = $exiftool->GetInfo('ImageWidth');

				my $shave = ( $info->{ImageWidth} - 800 ) / 2;
				#warn "convert -shave ${shave}x0 '800x/tmp.jpg' '800x/$out'";
				#system "convert -shave $shave '800x/tmp.jpg' '800x/$out'";
				system "convert -crop 800x600+$shave '800x/tmp.jpg' '800x/$out'";
				unlink "800x/tmp.jpg";
				#exit(1);
			}
		}
	}
	closedir $dh;
}
	
scan_dir($_) foreach @ARGV;


