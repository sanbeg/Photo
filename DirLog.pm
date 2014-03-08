package DirLog;
use strict;
use Carp;
use FileUtil ('copy_file');
my $file='.dirlog';
my $sep=' ';

#status A=added, R=removed, F=found, L=lost, T=transient (lost/removed+found)
my %_exists_now = (A=>1, T=>1, F=>1);

sub _read_log {
    my $stats = shift;
    my $logfh = shift;

    while (<$logfh>) {
	chomp;
	next unless m/([A-Z])$sep(.+)/;
	$stats->{$2}=$1;
    }
}


sub new {
    my $class = shift;
    my $dir = shift;
    my $opts = shift;
    my %stats;
    my $logfh;
    my %files;

    my $found_state = 'F';
    if (defined $opts->{state}) {
	$found_state = $opts->{state};
	croak "Invalid state: $found_state"
	    unless $found_state =~ m/^[ARFLT]$/;
    };


    #if log exists, scan it in
    open $logfh, '<', "$dir/$file" and do {
	_read_log(\%stats,$logfh);
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
	    $stats{$k} = $found_state;
	} elsif ($v eq 'R' or $v eq 'L') {
	    $stats{$k} = 'T';
	}

    }
    
    delete $stats{$file};
    bless \%stats, $class;
}

sub from_file {
    my $class = shift;
    my $file = shift;
    my %stats;
    open my($logfh), '<', $file or croak "$file: $!";
    _read_log(\%stats, $logfh);
    close $logfh;
    bless \%stats, $class;
}


sub write {
    my $self=shift;
    my $dir = shift;
    my $logfh;

    croak "Need a directory to write the log in" unless defined $dir;

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
    return (defined($self->{$file}) and $_exists_now{$self->{$file}});
}

sub set {
    $_[0]{$_[1]}=$_[2];
}

sub add {
    set (@_, 'A');
}
sub remove {
    set (@_, 'R');
}

my @order = ('R', 'L', 'A', 'F', 'T');
my %order = map { $order[$_] => $_ } 0..$#order;

sub combine {
    my ($class, $lhs, $rhs) = @_;
    my %stats = %$lhs;
    while (my($file,$state) = each %$rhs) {
	if (not defined $stats{$file}) {
	    $stats{$file} = $state;
	} elsif ($order{$state} < $order{ $stats{$file} } ){
	    $stats{$file} = $state;
	}
    }
    bless \%stats, $class;
}

sub sync_dir_to_file {
    my ($self, $self_dir, $other) = @_;

    while (my($file,$other_state) = each %$other) {
      my $self_file = $self->{$file};
      $self_file = '' unless defined $self_file;

      warn "$file $self_file -> $other_state"
	unless $self_file eq $other_state;

      if (not defined $self->{$file}) {
	$self->{$file} = $other_state;
	warn "Missing $file" if $_exists_now{$other_state};
      } elsif ($order{$other_state} < $order{ $self->{$file} } ){
	#warn "$file $self->{$file} -> $other_state";
	if ($self->exists_now($file)) {
	  unlink "$self_dir/$file" unless $other->exists_now($file);
	  warn "rm $self_dir/$file" unless $other->exists_now($file);
	} else {
	  warn "missing $file" if $other->exists_now($file);
	}
	$self->{$file} = $other_state;
      } else {
	#warn "$file $self->{$file} -> $other_state";
      }
    }
  }    

sub sync_dir {
    my ($self,$self_dir,$other_dir) = @_;
    my $other = ref($other_dir)? $other_dir : ref($self)->new($other_dir);

    while (my($file,$state) = each %$other) {
	if (not defined $self->{$file}) {
	    $self->{$file} = $state;
	    copy_file("$other_dir/$file", "$self_dir/$file")
		if $_exists_now{$state};
	} elsif ($order{$state} < $order{ $self->{$file} } ){
	    warn "$file $self->{$file} -> $state";
	    if ($self->exists_now($file)) {
		unlink "$self_dir/$file" unless $other->exists_now($file);
	    } else {
		copy_file("$other_dir/$file", "$self_dir/$file")
		    if $other->exists_now($file);
	    }
	    $self->{$file} = $state;
	}
    }
}    
1;
