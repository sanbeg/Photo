package CPPic;

use strict;
use Carp;
use File::Glob qw(:globally :nocase);
use FileUtil ('copy_file');
use DirLog;
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
	    croak "Can't freshen $dst: no files found! ($prefix.$suffix)" 
	      unless defined $start;
	    if ($start =~ m:/${prefix}([0-9]+).*\.$suffix:i) {
		$self->{from} = $1+1;
		last;
	    } else {
		warn "freshen boundary; skip file: $start";
	    }
	}

	#check dirlog, to see if the start previously existed.
	my $dirlog = DirLog->new($dst);
	for (;;) {
	  if ($dirlog->existed("$prefix$self->{from}.$suffix")) {
	    ++ $self->{from};
	  } else {
	    last;
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



sub copy_range( $$;$ ) {
    my $template="${prefix}%.4i.$suffix";
    my ($self,$src,$dst,$dirlog) = @_;
    my ($to,$from) = ($self->{to}, $self->{from});
    $dst ||= $self->{dst};

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
	    $start =~ m:${prefix}([0-9]+)\.$suffix:i;
	    $from = $1;
	}
	warn "copy from $from to $to\n" if $verbose;
	die "no from $prefix $glob[0]" unless defined $from;
    };

    die "no from" unless defined $from;
    foreach my $fileno ($from .. $to) {
	my $file = sprintf $template, $fileno;
	my $srcf = "$src/".($downcase?uc($file):$file);
	if (-r $srcf) {
	    my $base = $downcase ? lc($file) : $file;
	    my $dstf = "$dst/$base";

	    if (defined($dirlog) and $dirlog->existed($base)) {
		warn "not replacing $file\n";
		next;
	    }
	    if ($test) {
		#print "test $file -> $dstf\n";
	    } elsif ($move) {
		#move ($srcf, $dstf) or die "$file -> $dstf: $!\n";
	    } else {
		warn "copy: $srcf -> $dstf";
		copy_file ($srcf, $dstf) or die "$file -> $dstf: $!\n";
	    }
	    push @{$self->{copied}}, $dstf;
	    $dirlog->add($base) if defined $dirlog;
	    warn "copy $file\n" if $verbose>1;
	} else {
	    warn "skip $srcf\n" if $verbose>1;
	}
    }
}

sub copy_all($;$) {
    my ($self,$dst) = @_;
    my $dirlog = DirLog->new($dst);
    foreach my $src (@{$self->{folders}}) {
	eval {
	    $self->copy_range($src,$dst,$dirlog);
	}
    }
    $dirlog->write($dst);
};

sub copied {
    return defined($_[0]{copied}) ? $_[0]{copied} : [];
};

sub rotate( $ ) {
#do auto rotation
    my $self = shift;
    if (defined $self->{copied} and @{$self->{copied}}) {
	print "rotating images...\n";
	system 'jhead', '-ft', '-autorot', @{$self->{copied}};
    }
};

our $etc_mtab = '/etc/mtab';
sub find_cameras( $ ) {
    my $self = shift;
    my ($MTAB,$DCIM);
    my $f = $self->{folders} = [];

    open $MTAB, '<', $etc_mtab;
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
