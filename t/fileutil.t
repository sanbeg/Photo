use lib '.';
use FileUtil('copy_file');
use Test::More;
use Test::Directory;

my $td = Test::Directory->new;

$td->mkdir('src');
$td->touch('src/file');
$td->mkdir('dst');

copy_file( $td->path('src/file'), $td->path('dst/file') );
$td->has( 'dst/file', 'file was copied' );

copy_file( $td->path('src/file'), $td->path('dst/file.txt') );
$td->has( 'dst/file.txt', 'file was copied' );


$td->is_ok;
done_testing;
