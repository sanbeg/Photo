#! /usr/bin/perl -w

use Test::More;
use lib '.';
use constant MODULE => 'Test::Directory';

use_ok(MODULE);

my $d='tmp/td';
{
    my $td = MODULE->new($d);
    $td->touch(1,2);
    ok(-d $d, 'Dir was created');
    ok(-f "$d/2", 'file was created');
    ok($td->has(1), 'object finds file');
    ok($td->has(2), 'object finds file');
    ok(!$td->has(3), 'object finds file');

    is($td->count_missing, 0, "no missing files");
    is($td->count_unknown, 0, "no unknown files");
    $td->missing_ok("no missing files");
    $td->unknown_ok("no unknown files");
    $td->ok("No missing or unknown files");
}

ok (!-d $d, 'Dir was removed');

done_testing();
