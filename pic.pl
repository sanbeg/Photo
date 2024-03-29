#! /usr/bin/perl -w

use strict;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin";
use CPPic;
use DetectRoll;
use CamRoll;
use Data::Dumper;

#unimplemented
my $move;
my $only_last_folder;
my @fake_camera;
my %opt = (fresh=>1, rotate=>1);
GetOptions(
    \%opt,
    'from=i', 
    'to=i',
    'rotate!'=>,
    'freshen!', 
    'video!',
    'move!'=>\$move, 
    'test!'=>\$CPPic::test,
    'verbose+'=>\$CPPic::verbose,
    'prefix=s'=>\$CPPic::prefix,
    'suffix=s'=>\$CPPic::suffix,
    'last!'=>\$only_last_folder,
    #testing opt, local copy of camera.  Better than mount -oloop?
    'fake=s'=>\@fake_camera, 
    'fakesub=s@'=> sub{push @fake_camera, <$_[1]/*>},
    ) or die;

if ($opt{video}) {
    $CPPic::suffix = 'mov';
    $opt{rotate} = 0;
}

umask 033;

my $dst = shift;
die "Copy to where?" unless defined $dst;
my $freshen=shift;
die "too many args" if @ARGV;

my $pic = CPPic->new;

if (@fake_camera) {
    $pic->{folders}=\@fake_camera;
} else {
    $pic->find_cameras;
}


warn Dumper($pic);
$pic->init_src;

$DetectRoll::prefix = $CPPic::prefix;
$DetectRoll::suffix = '.' . $CPPic::suffix;

if (-d $dst) {
    if ($freshen and $freshen ne $dst and ! $opt{video} ) {
	my ($dst1,$dst2) = DetectRoll->new($dst)->find_roll();
	my ($fresh1,$fresh2) = DetectRoll->new($freshen)->find_roll();
	#warn "DUr= $fresh1 $dst2";
	die "args in wrong order?" if defined $dst1 and $fresh1 >= $dst1;
    }
}else{
    $opt{fresh}=0;
};


my ($roll,$maxr) = CamRoll::find($pic);
CamRoll::kill($pic,$roll) if defined $roll;

if (defined $opt{from}) {
  warn "xxx";
    $pic->freshen($dst, $opt{from});
} elsif (defined $freshen) {
    my $refresh = ($freshen eq '') ? $dst : $freshen;
    warn "Freshening $refresh";

    $pic->freshen( $refresh );
    unless ( -d $dst ) {
	#create destination after we've verfied the source
	mkdir $dst or die "$dst: $!";
    }

    warn "copy starting from #$pic->{from}";

    eval {
      my $dr=DetectRoll->new($refresh);
      
      my ($left,$right) = $dr->find_roll;
      
      if ($left < $right) {
	print "last image is $left; earliest is $right\n";
	$pic->{from} = $left+1;
	$pic->{to} = $right-1;
	$only_last_folder=1;
      }
    }
} elsif ($opt{fresh}) {
    $pic->freshen( $dst );
}

if (defined $opt{to}) {
    $pic->{to} = $opt{to};
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

warn "copying to $dst";

$pic->copy_all($dst);

#todo - if there's a new folder due to number rollover, that won't be copied
#yet, so copy everything there.  If max(last_folder) < from, or last folder
#wasn't used?

#instead of last folder, find folder in range;
#i.e. imageno(folder)<imageno(prev_folder) => last rollover point.
#copy 

#DirLog->new($dst)->write($dst);

$pic->rotate if $opt{rotate};


