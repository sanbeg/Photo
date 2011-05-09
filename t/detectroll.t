#! /usr/bin/perl -w

use Test::More;
use lib '.';
use DetectRoll;

my $dir = 't/photos/labor-day';
my $dr=DetectRoll->new($dir);
ok($dr->has_roll, "detect rollover");
my ($left,$right) = $dr->find_roll;
is($left,30, 'Found newest photo');
is($right,9937, 'Found oldest photo');


done_testing();
