#! /usr/bin/perl -w

use Test::More;
use lib '.';
use TestDir;

my $d='tmp/td';
{
    my $td = TestDir->new($d);
    $td->touch(1,2);
    ok(-d $d, 'Dir was created');
    ok(-f "$d/2", 'file was created');
    ok($td->has(1), 'object finds file');
    ok($td->has(2), 'object finds file');
    ok(!$td->has(3), 'object finds file');
}
ok (!-d $d, 'Dir was removed');

done_testing();
