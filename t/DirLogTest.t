# -*- cperl -*-

use strict;
use warnings;
use Test::More;

use lib '.';
use DirLog;

my $log = DirLog->new('t/photos/labor-day');
ok($log, 'got object');
ok($log->exists_now('DSC_0001.JPG'), 'found file');
ok(not($log->exists_now('DSC_0031.JPG')), "didn't find file");

my $log_a = DirLog->new('t/tmp/a');
my $log_b = DirLog->new('t/tmp/b');

for my $i (1 .. 5 ) {
  $log_a->add($i);
  $log_b->add($i);
  system("touch t/tmp/a/$i t/tmp/b/$i");
};

use Data::Dumper;
ok($log_a->remove(2));
unlink("t/tmp/a/2");
ok($log_b->remove(3));
unlink("t/tmp/b/3");

#warn Dumper($log_a);
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
  
  #warn Dumper($log_b,$log_c);
  
  for my $i (2,3) {
    ok(not($log_c->exists_now($i)), "$i not in combined");
  };
};

do {
  $log_b->write('t/tmp/b');  
  $log_a->sync_dir('t/tmp/a', DirLog->new('t/tmp/b'));
  
  for my $i (1 .. 5) {
    ok($log_a->existed($i), "$i existed");
  }
  
  #warn Dumper($log_b,$log_c);
  
  for my $i (2,3) {
    ok(not($log_a->exists_now($i)), "$i not in combined");
    ok(not(-f "t/tmp/a/$i"), "$i was removed");
  };
};


done_testing;
