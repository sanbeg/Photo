#! /usr/bin/perl -w

use strict;
use Test::More;
use lib '.';
use CPPic;
use CamRoll;

$CPPic::prefix='x_';

my $pic = CPPic->new;
$pic->{folders} = [map "t/cameras/roll/$_", 1..2];

my ($roll,$maxr) = CamRoll::find($pic);
ok($roll, 'found rollover');
CamRoll::kill($pic,$roll);
#print "@{$pic->{folders}}\n";
is(grep(m/1/, @{$pic->{folders}}), 0, 'folder was removed');
is(grep(m/2/, @{$pic->{folders}}), 1, 'folder was not removed');

done_testing();
