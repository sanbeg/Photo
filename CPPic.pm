package CPPic;

use strict;
use Carp;
use File::Glob qw(:globally :nocase);

our $move;
our $downcase=1;
our $prefix; # = 'dsc_';
our $suffix = 'jpg';
our $test;
our $verbose=0;

#my $template="${prefix}%.4i.$suffix";

sub freshen( $$;$ ) {
    my $self = shift;
    my $dst = $self->{dst} = shift;
    $self->{from} = shift;

    croak "$dst: $!" unless -d $dst;
    #sort probably not needed, but would screw up badly if it was.
    my @glob = sort <\Q$dst\E/${prefix}*.$suffix>;
    unless (defined $self->{from}) {
	#my $start = shift @glob;
	for (;;)  {
	    my $start = pop @glob;
	    croak "Can't freshen $dst: no files found!" unless defined $start;
	    if ($start =~ m:/${prefix}([0-9]+).*\.$suffix:i) {
		$self->{from} = $1+1;
		last;
	    } else {
		warn "freshen boundary; skip file: $start";
	    }
	}
    }
}

sub init_src ($) {
    my $self = shift;

    unless (defined $prefix) {
	my %candidates;
	foreach my $src (@{$self->{folders}}) {
	    opendir my($dh), $src or die "$src: $!";
	    
	    while (my $file = readdir($dh)) {
		if ($file =~ m/(.+?)[0-9]+\.$suffix/i) {
		    #warn "prefix=$1" if $verbose>2;
		    $candidates{$1} ++;
		}
	    }
	    closedir $dh;
	}
	my @c = keys %candidates;
	if (@c > 1) {
	    die "Multiple prefixes found: " . join (", ", @c);
	} else {
	    $prefix = $downcase? lc($c[0]) : $c[0];
	}
    }
}

sub downcase( $ ) {
    my $self = shift;
#downcase after we've read dst.
    $self->{prefix} = uc $self->{prefix};
    $self->{suffix} = uc $self->{suffix};
}

sub _copy ( $$ ) {
    my ($src, $dst) = @_;
    my ($S,$D);
    open $S, $src or die "$src: $!";
    open $D, ">$dst" or die "$dst: $!";

    my ($buf,$len);
    while (1) {
	$len = sysread $S,$buf,1024;
	die "$src: $!" unless defined $len;
	last if $len == 0;
	syswrite $D,$buf,$len or die "$dst: $!";
    }
    close $S;
    close $D;
}


sub copy_range( $$;$ ) {
    my $template="${prefix}%.4i.$suffix";
    my $self = shift;
    my ($to,$from) = ($self->{to}, $self->{from});
    my ($src,$dst) = @_;
    $dst ||= $self->{dst};

    $self->{copied} = [];

    unless (defined($to) and defined($from)) {
	#my @glob = sort <$src/${prefix}*.$suffix>;

	my $prefix = $downcase ? uc($prefix) : $prefix;
	my $suffix = $suffix ? uc($suffix) : $suffix;

	
	my @glob;
	opendir my($dh), $src or die "$src: $!";
	@glob = sort grep {m/^${prefix}.+\.$suffix$/i} readdir($dh);
	closedir $dh;

	die "No photos found in $src" unless @glob;
	unless (defined $to) {
	    my $end = $glob[$#glob];
	    #warn "$end => ${prefix}_([0-9]+)\.$suffix";
	    $end =~ m:${prefix}([0-9]+)\.$suffix:i;
	    $to = $1;
	    die "Where does it end?" unless defined $to;
	};
	#this may be broken, should just call freshen()?
	unless (defined $from) {
	    my $start = $glob[0];
	    $start =~ m:${prefix}([0-9]+)\.$suffix:;
	    $from = $1;
	}
	warn "copy from $from to $to\n" if $verbose;
	die "no from $prefix $glob[0]" unless defined $from;
    };

    die "no from" unless defined $from;
    foreach my $fileno ($from .. $to) {
	my $file = sprintf $template, $fileno;
#    my $srcf = "$src/$file";
	my $srcf = "$src/".($downcase?uc($file):$file);
	if (-r $srcf) {
	    #my $dstf = $downcase?lc("$dst/$file"):"$dst/$file";
	    my $dstf = $downcase?($dst."/".lc($file)):"$dst/$file";
	    if ($test) {
		#print "test $file -> $dstf\n";
	    } elsif ($move) {
		#move ($srcf, $dstf) or die "$file -> $dstf: $!\n";
	    } else {
		warn "copy: $srcf -> $dstf";
		_copy ($srcf, $dstf) or die "$file -> $dstf: $!\n";
	    }
	    push @{$self->{copied}}, $dstf;
	    warn "copy $file\n" if $verbose>1;
	} else {
	    warn "skip $srcf\n" if $verbose>1;
	}
    }
}

sub copy_all($;$) {
    $_[0]->copy_range($_,$_[1]) foreach @{$_[0]->{folders}};
};


sub rotate( $ ) {
#do auto rotation
    my $self = shift;
    if (@{$self->{copied}}) {
	print "rotating images...\n";
	system 'jhead', '-autorot', @{$self->{copied}};
    }
};

sub find_cameras( $ ) {
    my $self = shift;
    my ($MTAB,$DCIM);
    my $f = $self->{folders} = [];

    open $MTAB, '/etc/mtab';
    while (<$MTAB>) {
	my ($dev,$dir,$fs) = split ' ';
	$dir =~ s/\\([0-8]{3})/chr oct $1/ge;
	opendir $DCIM, "$dir/dcim" and do {
	    while (my $folder = readdir $DCIM) {
		next if $folder eq '.' or $folder eq '..';
		push @{$f}, "$dir/DCIM/$folder";
		print "add: $dir/DCIM/$folder\n" if $verbose;

	    }
	    
	    closedir $DCIM;
	}
	
    };
    close $MTAB;
};

sub new( $ ) {
    my $class = shift;
    bless {}, $class;
};

1;
