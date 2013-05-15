package FileUtil;

use Exporter;
our @ISA = 'Exporter';
our @EXPORT_OK = ('copy_timestamp', 'copy_file');

sub copy_timestamp( $$ ) {
    my ($src,$dst) = @_;
    
    my @stat = stat $src or die "stat $src: $!";
    my ($at,$mt) = @stat[8,9];
    utime $at,$mt, $dst or die "utime $dst: $!";
}

sub copy_file ( $$ ) {
    my ($src, $dst) = @_;
    my $real_dst = $dst;
    $dst =~ s/\..+$/.tmp/;

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
    unless ($dst eq $real_dst) {
	rename $dst, $real_dst or die "$real_dst: $!";
    }
    copy_timestamp $src, $real_dst;
}

1;
