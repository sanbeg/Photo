# -*- cperl -*-

use strict;
use warnings;
use Test::More;

use lib '.';
use DirLog;

use lib '../Test-Directory/lib';
use Test::Directory;

my $log = DirLog->new('t/photos/labor-day');
ok($log, 'got object');
ok($log->exists_now('DSC_0001.JPG'), 'found file');
ok(not($log->exists_now('DSC_0031.JPG')), "didn't find file");

my $tmpdir = Test::Directory->new;

$tmpdir->mkdir('a');
$tmpdir->mkdir('b');

my $log_a = DirLog->new( $tmpdir->path('a'));
my $log_b = DirLog->new( $tmpdir->path('b'));

for my $i (1 .. 5 ) {
  $log_a->add($i);
  $log_b->add($i);
  $tmpdir->touch("a/$i", "b/$i");
};

ok($log_a->remove(2));
ok($log_b->remove(3));

$tmpdir->remove_files( 'a/2', 'b/3');

ok(not($log_a->exists_now(2)), "2 was removed from a");

do {
  my $log_c = DirLog->combine($log_a,$log_b);

  for my $i (1 .. 5) {
    is (
	$log_c->exists_now($i),
	( $log_a->exists_now($i) and $log_b->exists_now($i) ),
	"a and b $i"
       );
    ok($log_c->existed($i), "$i existed");
  }

  for my $i (2,3) {
    ok(not($log_c->exists_now($i)), "$i not in combined");
  };
};

do {
  $log_b->write( $tmpdir->path('b'));  
  $log_a->sync_dir( $tmpdir->path('a'), DirLog->new( $tmpdir->path('b')));

  for my $i (1 .. 5) {
    ok($log_a->existed($i), "$i existed");
  }

  for my $i (2,3) {
    ok(not($log_a->exists_now($i)), "$i not in combined");
    $tmpdir->hasnt("a/$i", "$i was removed");
  };
};

$tmpdir->is_ok;

done_testing;
