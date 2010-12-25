package CamRoll;
use CPPic;

sub find ( $ ) {
    my $pic = shift;
    my %shutter_count;
    my %filenum;
    my %dirnum;
    my $DH;
    foreach my $dir (@{$pic->{folders}}) {
	print "$dir\n";
	$dir =~ m:.+/([0-9]+): and do {
	    my $dirn=$1;
	    print "$dirn\n";
	    opendir $DH, $dir or die "$dir: $!";
	    while (my $fn = readdir $DH) {
		if ($fn =~ m/(?:$CPPic::prefix).*?([0-9]+)/i) {
		    $filenum{$dirn} = $1;
		    $dirnum{$dirn} = $dir;
		    last;
		}
	    }
	    closedir $DH;
	}
    }
    
    my $max_fn=0;
    my $roll;
    foreach my $dirn (sort {$a <=> $b} keys %filenum) {
	my $fn = $filenum{$dirn};
	warn "$dirn $fn $max_fn";
	if ($fn < $max_fn) {
	    warn "camera rolled @ $dirn";
	    $roll=$dirn;
	};
	$max_fn = $fn;
    }
    
    if (defined $roll) {
	my @dirs;
	while (my ($num,$name) = each %dirnum) {
	    push @dirs, $name if $num >= $roll;
	}
	my ($min_r, $max_r) = (9999,0);
	foreach my $dir (@dirs) {
	    warn $dir;
	    opendir $DH, $dir or die "$dir: $!";
	    while (my $fn = readdir $DH) {
		if ($fn =~ m/(?:$CPPic::prefix).*?([0-9]+)/i) {
		    my $n = $1;
		    $min_r = $n if $n < $min_r;
		    $max_r = $n if $n > $max_r;
		}
	    }
	    closedir $DH;
	}
	print "$min_r $max_r $roll\n";
	#....
	return ($roll,$max_r);
    }
    return undef;
}

sub kill ( $$ ) {
    my $pic=shift;
    my $target = shift;
    my @folders;

    #refactor from above?
    foreach my $dir (@{$pic->{folders}}) {
	print "$dir\n";
	$dir =~ m:.+/([0-9]+): and do {
	    my $dirn=$1;
	    if ($dirn >= $target) {
		print "KEEP: $dirn $dir\n";
		push @folders, $dir ;
	    }
	}
    }
    @{$pic->{folders}} = @folders;
}
    
1;
