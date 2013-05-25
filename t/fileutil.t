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
$td->create( 'lock.lck' );
chmod( 0, $td{lock}, $td{'lock.lck'});

dies_ok { 
	copy_file( $td{lock}, $td{copy});
} "Die if can't read";

dies_ok { 
	copy_file( $td{'src/file.txt'}, $td{'lock'});
}	"Die if can't write, straight copy";
# dies_ok { 
# 	copy_file( $td{'src/file.txt'}, $td{'lock.lck'});
# }	"Die if can't write, copy/rename";
 
$td->is_ok;
done_testing;
