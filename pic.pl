#! /usr/bin/perl -w

use strict;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin";
use lib "$FindBin::Bin/../perl";
use CPPic;
use DetectRoll;
use CamRoll;

my $freshen;
#unimplemented
my ($from,$to);
my $rotate=1;
my $move;
my $only_last_folder;
my @fake_camera;
GetOptions(
    'from=i'=>\$from, 'to=i'=>\$to, 'rotate!'=>\$rotate, 
    'freshen:s'=>\$freshen, 'move!'=>\$move, 
    'test!'=>\$CPPic::test, 'verbose+'=>\$CPPic::verbose,
    'prefix=s'=>\$CPPic::prefix, 'last!'=>\$only_last_folder,
#testing opt, local copy of camera.  Better than mount -oloop?
    'fake=s'=>\@fake_camera, 'fakesub=s@'=> sub{push @fake_camera, <$_[1]/*>},
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

if (@fake_camera) {
    $pic->{folders}=\@fake_camera;
} else {
    $pic->find_cameras;
}

$pic->init_src;

my ($roll,$maxr) = CamRoll::find($pic);
CamRoll::kill($pic,$roll) if defined $roll;

if (defined $from) {
    $pic->freshen($dst, $from);
} elsif (defined $freshen) {
    my $refresh = ($freshen eq '') ? $dst : $freshen;
    warn "Freshening $refresh";
    $pic->freshen( $refresh );
    warn $pic->{from};

    my $dr=DetectRoll->new($refresh);

    my ($left,$right) = $dr->find_roll;
    if ($left < $right) {
	print "last image is $left; earliest is $right\n";
	$pic->{from} = $left+1;
	$pic->{to} = $right-1;
	$only_last_folder=1;
    }
} elsif ($do_fresh) {
    $pic->freshen( $dst );
}

if ($only_last_folder) {
    my @sorted_folders;
    my %max_folder;
    for (@{$pic->{folders}}) {
      m:([0-9]+)[^/]+$:;
	my $t=$_;
	my $n=$1;
	$t=~s/$n//;
	if (! defined($max_folder{$t}) or $n > $max_folder{$t}[0]) {
	    #warn "$t => $n";
	    $max_folder{$t}=[$n,$_];
	}
	$sorted_folders[$n]=$_;
	#print "$1 : $_\n";
    }
    #my $f = pop @sorted_folders;
    @{$pic->{folders}} = map $_->[1], values %max_folder;
    print "$_\n" for @{$pic->{folders}};
    #exit 1;
}


$pic->copy_all($dst);

#todo - if there's a new folder due to number rollover, that won't be copied
#yet, so copy everything there.  If max(last_folder) < from, or last folder
#wasn't used?

#instead of last folder, find folder in range;
#i.e. imageno(folder)<imageno(prev_folder) => last rollover point.
#copy 

$pic->rotate if $rotate;
