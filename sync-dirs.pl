#! /usr/bin/perl -w

use strict;
use warnings FATAL=>'uninitialized';

my $src = shift;
my $dst = shift;

my %hash;

sub listdir( $$ );
sub listdir ( $$ ) {
    my @dirlist;
    my ($pre,$dir) = @_;
    my @rv;

    opendir my($dh), "$pre/$dir" or die "$pre/$dir: $!";
    my $f;
    while (defined ($f = readdir($dh))) {
	if (-d "$pre/$dir/$f") {
	    push @rv, listdir($pre, "$dir/$f")
		unless $f =~ /^..?$/;
	} elsif (-f "$pre/$dir/$f") {
	    push @rv, "$dir/$f";
	}
    }
    closedir $dh;
    return @rv;
}

my $CREATE=-1;
my $DELETE=-2;
my $REPLACE = -3;

my %opts = ($CREATE=>'create', $DELETE=>'delete', $REPLACE=>'replace');

foreach my $file (listdir $src, '.') {
    #print "found $file\n";
    $hash{$file} = -M "$src/$file";
};

my $keep_dst = 0;
my $rm_dst = 0;

foreach my $file (listdir $dst, '.') {
    if (exists($hash{$file} )) {
	$keep_dst++;
#check modification time.

	if ($hash{$file} < -M "$dst/$file") {
	    $hash{$file} = $REPLACE;
	}  else {
	    delete $hash{$file};
	}
    } else {
	$rm_dst++;
	$hash{$file} = $DELETE;
    }
};

if ($rm_dst > 0 and $keep_dst == 0) {
    die "That would delete everything in $dst !\n";
}

#while (my ($k,$v) = each %hash) {
foreach my $k (sort keys %hash) { my $v = $hash{$k};
    #print "$k => $v ", defined($opts{$v})?$opts{$v}:'create', "\n";
    if ($v == $CREATE or $v > 0) {
	print "creating $k\n";
    } elsif ($v == $REPLACE) {
	print "updating $k\n";
    } elsif ($v == $DELETE) {
	print "deleting $k\n";
    }
}



	
