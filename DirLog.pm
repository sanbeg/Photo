package DirLog;
use Carp;
my $file='.dirlog';
my $sep=' ';

#status A=added, R=removed, F=found, L=lost, T=transient (lost/removed+found)
my %_exists_now = (A=>1, T=>1, F=>1);

sub new {
    my $class = shift;
    my $dir = shift;
    my %stats;
    my $logfh;
    my %files;

    open $logfh, "$dir/$file" and do {
	while (<$logfh>) {
	    chomp;
	    next unless m/([A-Z])$sep(.+)/;
	    $stats{$2}=$1;
	}
	close $logfh;
    };
    opendir my($dh), $dir or croak "$dir: $!";
    while (my $file = readdir $dh) {
	next if $file =~ /^\./;
	next if -d "$dir/$file";
	next unless -f "$dir/$file";
	$files{$file} = 1;
    };
    closedir $dh;

    while (my ($k,$v) = each %stats) {
	if (not -f "$dir/$k") {
	    if ($_exists_now{$v}) {
		$stats{$k} = 'L';
	    }
	} elsif ($v eq 'R' or $v eq 'L') {
	    $stats{$k} = 'T';
	}
    };
    while (my ($k,$v) = each %files ) {
	$v = $stats{$k};
	if (not defined $v) {
	    $stats{$k} = 'F';
	} elsif ($v eq 'R' or $v eq 'L') {
	    $stats{$k} = 'T';
	}

    }
    
    delete $stats{$file};
    bless \%stats, $class;
}

sub write {
    my $self=shift;
    my $dir = shift;
    my $logfh;

    open $logfh, ">$dir/$file" or die "$dir/$file";
    foreach my $file (sort keys %{$self}) {
	print $logfh "$self->{$file}$sep$file\n";
    }
    close $logfh;
}

sub existed {
    my $self = shift;
    my $file = shift;
    return defined $self->{$file};
}

sub exists_now {
    my $self = shift;
    my $file = shift;
    return defined $self->{$file} and $_exists_now{$self->{$file}};
}

# sub add {
#     my $self = shift;
#     my $file = shift;
#     $self->{$file}='A';
# }
# sub remove {
#     my $self = shift;
#     my $file = shift;
#     $self->{$file}='R';
# }

sub set {
    $_[0]{$_[1]}=$_[2];
}

sub add {
    set (@_, 'A');
}
sub remove {
    set (@_, 'R');
}

1;
