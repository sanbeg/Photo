use lib '.';
use Test::More;
use CPPic;
use Test::Directory;

my $pic = CPPic->new;
$pic->{folders} = [ 't/photos/labor-day' ];

undef $CPPic::prefix;
$pic->init_src;
is( $CPPic::prefix, 'dsc_', 'found prefix');

$CPPic::prefix = 'x_';
my $td = Test::Directory->new;
$td->touch( sprintf "x_%0.4i.jpg", $_ ) for 1..10;

$pic->freshen( $td->path );
is ($pic->{from}, 11, 'found next index');

my $td_src = Test::Directory->new;
use constant TEMPLATE => "x_%0.4i.jpg";
$td_src->touch( sprintf TEMPLATE, $_ ) for 1..20;
$td->remove_files('x_0005.jpg');

$CPPic::downcase = 0; #should be 0 is fs is case-sensitive
$CPPic::verbose = 0;
$pic->copy_range( $td_src->path, $td->path );

$td->hasnt('x_0005.jpg', 'removed file not restored');
$td->has  ( sprintf TEMPLATE, $_) for 11..20;

my $cam = Test::Directory->new;
my $cam_path = $cam->path;
my $fake_mtab = qq[
/dev/sdb1 $cam_path vfat defaults
];

$CPPic::etc_mtab = \$fake_mtab;

$cam->mkdir('dcim');
$cam->mkdir('dcim/100');

$pic->find_cameras;
is ( $pic->{folders}[0], $cam->path('DCIM/100'), 'got first folder');
$cam->is_ok;
warn $cam->path;

done_testing;
