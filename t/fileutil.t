use lib '.';
use FileUtil('copy_file');
use Test::More;
use Test::Directory;
use Test::Exception;

my $td = Test::Directory->new;

$td->mkdir('src');
$td->touch('src/file');
$td->mkdir('dst');

copy_file( $td->path('src/file'), $td->path('dst/file') );
$td->has( 'dst/file', 'file was copied' );

$td->create( 'src/file.txt', content=>'hello world' );
copy_file( $td->path('src/file.txt'), $td->path('dst/file.txt') );
$td->has( 'dst/file.txt', 'file was copied' );

$td->create( 'lock' );
chmod( 0, $td->path('lock') );

dies_ok { 
	copy_file( $td->path('lock'), $td->path('copy'));
} "Die if can't read";

throws_ok { 
	copy_file( $td->path('src/file.txt'), $td->path('lock'));
}	qr(/lock:), "Die if can't write, straight copy";
 
$td->is_ok;
done_testing;
