#! /usr/bin/perl -w

use strict;

my $dir = shift;
$dir //= '.';
opendir DH, $dir or die "$dir: $!";

my %map;
while ($_ = readdir DH) {
    next unless m/^(.+?)([0-9]+)\.jpg/i;
    $map{$2} = $1;
}

#while (my($k,$v) = each %map) {print "$k = $v\n";}
my @list = sort keys %map;
for my $i (1 .. $#list) {
    #check for matching prefix
    if ( $map{$list[$i-1]} eq $map{$list[$i]}) {
	for my $j ($list[$i-1]+1 .. $list[$i]-1) {
	    print $map{$list[$i]} . $j . ".jpg\n";
	}
	#print "$list[$i-1] ", $list[$i]-1, "\n";
    }
}


	
