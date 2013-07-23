package DetectRoll;
use strict;
use Carp;
use Image::ExifTool ':Public';

our $suffix='.jpg';
our $prefix = 'dsc_';

sub new ( $$ ) {
    my ($class, $dir) = @_;
    bless {dir=>$dir}, $class;
}

sub shutter_count( $$ ) {
    my $self=shift;
    my $file=shift;

    unless (exists $self->{sc}{$file}) {
      $self->{sc}{$file} = ImageInfo($self->{dir}."/".$file)->{ShutterCount};
      die "Can't find shutter count" unless defined $self->{sc}{$file};
    }

    return $self->{sc}{$file};
}

sub open_dir {
    my $self=$_[0];
    if (defined $self->{DH}) {
	rewinddir $self->{DH};
    } else {
	opendir $self->{DH}, $self->{dir} or croak "$self->{dir}: $!";
    }
}

sub DESTROY {
    my $self=$_[0];
    if (defined $self->{DH}) {
	closedir $self->{DH};
    }
}
sub has_roll {
    &open_dir;
    my $self=shift;


    my ($min,$max);
    my ($minf,$maxf);
    while (my $fn = readdir $self->{DH}) {
	next unless $fn =~ /([0-9]+).*\Q$suffix/i;
	if (!defined($min) or $min > $1) {
	    $minf=$fn;
	    $min=$1;
	}
	if (!defined($max) or $max < $1) {
	    $maxf=$fn;
	    $max=$1;
	}
    }

    if (defined $min and defined $max) {
	return ($self->shutter_count($minf) > $self->shutter_count($maxf));
    }
};

our $debug;

sub find_roll {
    use integer;
    &open_dir;
    my $self=shift;
    my %filenames;

    my ($min,$max, $minf, $maxf);

    while (my $fn = readdir $self->{DH}) {
	next unless $fn =~ /$prefix([0-9]+).*\Q$suffix/i; #bogus paths will loop
	$filenames{int($1)} = $fn;
	if (!defined($min) or $min > $1) {
	    $min=$1;
	    $minf=$fn;
	}
	if (!defined($max) or $max < $1) {
	    $max=$1;
	    $maxf=$fn;
	}
    }

    die "No files found" unless keys %filenames;

    my $mid=int(($min+$max)/2);
    my $left;
    my $right;
    for (;;){
	$mid=int($mid);
	$left=$right=$mid;
	-- $left while $left>=$min and ! exists $filenames{$left};
	++ $right while $right <= $max and ! exists $filenames{$right};
	warn "compare $min $left $mid $right $max" if $debug;
	warn "$minf $maxf" if $debug;
	warn "$filenames{$left} $filenames{$right}" if $debug;
	if ($self->shutter_count($filenames{$right}) >
	    $self->shutter_count($minf)) {
	    if ($mid == $max) {
		last;
	    } elsif (++$mid == $max) {
		next;
	    } else {
		$mid=($right+$max)/2;
	    }
	}
	elsif ($self->shutter_count($filenames{$left}) < 
	       $self->shutter_count($maxf)) {
	    $mid=($left+$min)/2;
	    last if $mid < $min;
	}else {
	    last;
	}
    }
    
    return ($left,$right);
}

1;
