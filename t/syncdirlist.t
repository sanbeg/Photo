use Test::More;
use Test::Directory;

use constant MOD => 'DirLog';

use_ok(MOD);
my $dir = Test::Directory->new;
$dir->mkdir('a');
$dir->mkdir('b');
my $la = MOD->new( $dir->path('a') );
my $lb = MOD->from_file( $dir->path('b') );

isa_ok($la, MOD);
isa_ok($lb, MOD);

for my $i (1 .. 10) {
  $la->add("$i.txt");
  $lb->add("$i.txt");
  $dir->touch("a/$i.txt", "b/$i.txt");
}

$dir->remove_files('a/3.txt', 'b/7.txt');
$la->remove('3.txt');
$lb->remove('7.txt');
$la->add('11.txt');
$lb->add('12.txt');
$dir->touch('a/11.txt', 'b/12.txt');

# $la->write( $dir->path('a') );
# $lb->write( $dir->path('b') );

$la->sync_dir_to_file( $dir->path('a'), $lb);
$dir->hasnt('a/7.txt');
$dir->hasnt('a/12.txt'); #can't copy, since we only have file
$dir->is_ok;

done_testing;

