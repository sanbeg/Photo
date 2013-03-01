package TestDir;
use Carp;

sub new {
    my $class = shift;
    my $dir = shift;
    #mkdir($dir) or croak "$dir: $!";
    mkdir $dir;
    croak "$dir: $!" unless -d $dir;
    bless {dir=>$dir}, $class;
}

sub DESTROY {
    # my $self = shift;
    # foreach my $file ( @{$self->{files}} ) {
    # 	unlink "$self->{dir}/$file";
    # };
    # system "rmdir $self->{dir}";
}

sub touch {
    my $self = shift;
    foreach my $file (@_) {
	open my($fh), '>', "$self->{dir}/$file";
	push @{$self->{files}}, $file;
    };
};

sub path {
    my ($self,$file) = @_;
    return "$self->{dir}/$file";
};

sub has {
    my ($self,$file) = @_;
    return -f "$self->{dir}/$file";
}



1;
