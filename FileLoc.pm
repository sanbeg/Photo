package FileLoc;
use strict;
sub new {
    my $class = shift;
    my $dir = shift;
    bless {dir=>$dir, dirs=>[], count=>0,max_ext_count=>0,file_loc=>{}}, $class;

}

sub scan_dir( $ ) {
    my $self=shift;
    my $dir = shift;
    opendir my($DH), "$self->{dir}/$dir" or die "$self->{dir}/$dir: $!";
    while (my $fn = readdir $DH) {
	my $dfn="$dir/$fn";
	my $pfn="$self->{dir}/$dfn";
	if (-d $pfn) {
	    unless ($fn =~ /^\./) {
		$self->scan_dir($dfn);
		push @{$self->{dirs}}, $dfn;
	    };
	    next;
	};
	my $ext='';
	if ($fn =~ /.\.([[:alnum:]]+)$/){
	    #$self->{ext_count}->{lc $1}++;
	    $ext = lc $1;
	}
	    
	next if defined $self->{ignore_ext}{$ext};
	next if defined($self->{only_ext}) and not($self->{only_ext}{$ext});
	if (-f $pfn) {
	    ++ $self->{count};
	    push @{$self->{file_loc}{$fn,-s $pfn}},$dfn;
	    if (++ $self->{ext_count}{$ext} > $self->{max_ext_count}) {
		$self->{max_ext_count} = $self->{ext_count}{$ext};
		$self->{max_ext} = $ext;
	    }
	}
    }

    closedir $DH;
}

sub ignore_extension {
    $_[0]{ignore_ext}{$_[1]}=1;
}
sub only_extension {
    $_[0]{only_ext}{$_[1]}=1;
}

sub max_ext {
    my $self = shift;
    return $self->{count}?
	($self->{max_ext}, $self->{max_ext_count}/$self->{count}):
	();
}
sub ext_count ( $$ ) {
    return $_[0]->{ext_count}{lc $_[1]};
}


1;
