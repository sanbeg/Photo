package DirHierLog;

use DirLog;
use File::Basename;

sub new {
    bless {}, shift;
};

sub set {
    my ($self, $path, $status) = @_;
    my ($file,$dir) = fileparse($path);
    $self->{$dir} //= DirLog->new($dir);
    $self->{$dir}->set($file,$status);
}

sub existed {
    my ($self,$path) = @_;
    my ($file,$dir) = fileparse($path);
    $self->{$dir} //= DirLog->new($dir);
    return defined($self->{$dir}) && $self->{$dir}->existed($file);
}

sub add {
    set (@_, 'A');
}
sub remove {
    set (@_, 'R');
}



sub write {
    my $self=shift;
    while (my($dir,$log) = each %{$self}) {
	$log->write($dir);
    }
}

1;
