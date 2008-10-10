#! /usr/bin/perl -w

=head1 NAME

cppic

=head1 SYNOPSIS

cppic I<SOURCE> I<DESTINATION> I<OPTIONS>

=head1 OPTIONS

=over

=item from I<N>

Copy pictures starting from number I<N>.

=item to I<N>

Copy pictures ending with number I<N>.

=item rotate

After copying, call I<jhead> to rotate the images.

=item freshen

Copy pictures starting from the last image already on I<DESTINATION>, to add
new pictures without replacing images that have been edited out.

=item move

Move the files instead of copying them.

=back

=cut

use strict;

use Getopt::Long;
use File::Copy;

umask 033;
my ($from,$to);
my $rotate=1;
my $freshen;
my $move;
my $downcase=1;
my $prefix = 'dsc';
my $suffix = 'jpg';
my $test;

GetOptions('from=i'=>\$from, 'to=i'=>\$to, 'rotate!'=>\$rotate, 
	   'freshen!'=>\$freshen, 'move!'=>\$move, 'test!'=>\$test);


my $src = shift;
my $dst = shift;

my $template="${prefix}_%.4i.$suffix";
my @copied;

if ($freshen) {
    my @glob = sort <$dst/${prefix}_*.$suffix>;
    die "Can't freshen: no files found!" unless @glob;
    unless (defined $from) {
	#my $start = shift @glob;
	my $start = pop @glob;
	$start =~ m:/${prefix}_([0-9]+)\.$suffix:;
	$from = $1+1;
    }
}

#downcase after we've read dst.
if ($downcase) {
    $prefix = uc $prefix;
    $suffix = uc $suffix;
}

unless (defined($to) and defined($from)) {
    my @glob = sort <$src/${prefix}_*.$suffix>;
    #print "@glob\n";
    die "No photos found in $src" unless @glob;
    unless (defined $to) {
	my $end = $glob[$#glob];
	#warn "$end => ${prefix}_([0-9]+)\.$suffix";
	$end =~ m:${prefix}_([0-9]+)\.$suffix:;
	$to = $1;
    };
    unless (defined $from) {
	my $start = $glob[0];
	$start =~ m:${prefix}_([0-9]+)\.$suffix:;
	$from = $1;
    }
    warn "copy from $from to $to\n";
};


foreach my $fileno ($from .. $to) {
    my $file = sprintf $template, $fileno;
#    my $srcf = "$src/$file";
    my $srcf = "$src/".($downcase?uc($file):$file);
    if (-r $srcf) {
	my $dstf = $downcase?lc("$dst/$file"):"$dst/$file";
	if ($test) {
	    #print "test $file -> $dstf\n";
	} elsif ($move) {
	    move ($srcf, $dstf) or die "$file -> $dstf: $!\n";
	} else {
	    copy ($srcf, $dstf) or die "$file -> $dstf: $!\n";
	}
	push @copied, $dstf;
	warn "copy $file\n";
    } else {
	warn "skip $srcf\n";
    }
}

#do auto rotation
if ($rotate and @copied) {
    print "rotating images...\n";
    system 'jhead', '-autorot', @copied;
};
