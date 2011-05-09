#! /usr/bin/perl -w

#TODO :  warn if sync would delete a directory with too many files.


use strict;
#use lib '.';
use Data::Dumper;
use File::Copy;
use Getopt::Long;

use FindBin;
use lib $FindBin::Bin;
use FileLoc;
use DirHierLog;

my $dry_run;
my $verbose;
my @ignore;
my @only;
my $do_log_dirs;
GetOptions ('n|dry-run'=>\$dry_run, verbose=>\$verbose, 
	    'ignore=s'=>\@ignore, 'only=s'=>\@only, 'log!'=>\$do_log_dirs);

my $dir = shift or die;
my $scan=FileLoc->new($dir);
$scan->ignore_extension($_) foreach @ignore;
$scan->only_extension($_) foreach @only;
$scan->scan_dir('.');
#print Dumper $scan->{only_ext};

my ($src_ext,$src_ext_cnt) = $scan->max_ext;
#print "$dir: @ext\n";# if @ext and defined $ext[0];
printf qq(Source type: "$src_ext" (%0.1f%%)\n), $src_ext_cnt*100;
#print Dumper $scan;
my $dir2 = shift;
my $scan2 = FileLoc->new($dir2);
$scan2->ignore_extension($_) foreach @ignore;
$scan2->only_extension($_) foreach @only;
$scan2->scan_dir('.');

my $OP_DEL=1;
my $OP_ADD=2;
my $OP_REPLACE=3; #ADD&DEL
my $OP_MOVE=4;
my %file_ops;

my @created_dirs;

sub copy_timestamp( @ ) {
    foreach (@_) {
	my @stat = stat "$scan->{dir}/$_" or die "stat $_: $!";
	my ($at,$mt) = @stat[8,9];
	utime $at,$mt, "$scan2->{dir}/$_" or die "utime $scan2->{dir}/$_: $!";
    }
}

my $count_rmdir=0;
my $count_rmdir_not_empty=0;
#count  old dirs
foreach (@{$scan2->{dirs}}) {
    unless (-d $scan->{dir}."/$_") {
	print "rmdir $_\n" if $verbose;
	opendir my($dh), "$scan2->{dir}/$_" or die;
	my $n_files=0;
	while (my $file = readdir $dh) {
	    ++ $n_files if -f "$scan2->{dir}/$_/$file";
	}
	closedir $dh;
	if ($n_files) {
	    print "$scan2->{dir}/$_ has $n_files files\n";
	    $count_rmdir_not_empty ++;
	}
	$count_rmdir++;
    }
}

if ($count_rmdir_not_empty and ! $dry_run) {
    die "This would remove $count_rmdir_not_empty non-empty directories!";
}


#create new dirs
foreach (@{$scan->{dirs}}) {
    unless (-d $scan2->{dir}."/$_") {
	print "mkdir $_\n" if $verbose;
	unless ($dry_run) {
	    mkdir $scan2->{dir}."/$_" 
		or die "$scan2->{dir}/$_: $!";
	}
	push @created_dirs, $_;
    }
}

while (my($fs,$fns) = each %{$scan->{file_loc}}) {
    my $fnd=$scan2->{file_loc}{$fs};
    if (defined $fnd) {
	#one copy, different location, just move it.
	if (@{$fns} == 1 and @{$fnd} == 1) {
	    unless ($$fns[0] eq $$fnd[0]) {
		print "Move $$fns[0] -> $$fnd[0]\n" if ($verbose);
	    $file_ops{$$fnd[0]}=[$OP_MOVE,$$fns[0]];
	    };
	} else {
	    my %src=map {$_=>1} @{$fns};
	    my %dst=map {$_=>1} @{$fnd};
	    foreach my $file (keys %dst) {
		delete $dst{$file} if delete $src{$file};
	    }
	    if ($verbose) {
		print "Delete $_\n" foreach keys %dst;
		print "Add $_\n" foreach keys %src;
	    }
	    $file_ops{$_} |= $OP_ADD foreach keys %src;
	    $file_ops{$_} |= $OP_DEL foreach keys %dst;
		
	}
    } else {
	#not on dst
	if ($verbose) {
	    print "Copy $_\n" foreach @{$fns};
	}
	$file_ops{$_} |= $OP_ADD foreach @{$fns};
    }
}

while (my($fs,$fnd) = each %{$scan2->{file_loc}}) {
    my $fns=$scan->{file_loc}{$fs};
    unless (defined $fns) {
	#not on dst, copy from src
	if ($verbose) {
	    print "Delete $_\n" foreach @{$fnd};
	}
	$file_ops{$_} |= $OP_DEL foreach @{$fnd};
    }
}


my @op_str = qw(nop Delete Create Update Rename);
my @op_stats;
my $dirlog;

if ($do_log_dirs) {
    warn "logging";
    $dirlog = DirHierLog->new() or die; 
    delete $file_ops{'.dirlog'} if defined $dirlog;
}

while (my ($f,$o) = each %file_ops) {
    my $op = ref($o)? $o->[0] : $o;

    if ($o == $OP_ADD and 
	defined($dirlog) and 
	$dirlog->existed($scan2->{dir}."/$f")) 
    {
	warn "Not replacing lost file: $scan2->{dir}/$f";
	delete $file_ops{$f};
	next;
    };
    
    $op_stats[$op]++;
}

foreach my $i (1 .. $#op_stats) {
    print "$op_str[$i] : $op_stats[$i]\n" if $op_stats[$i];
}
print "Make dir: ".@created_dirs."\n";
print "Remove dir: $count_rmdir\n";
print "Total files: source=",$scan->{count}," destination=",$scan2->{count},"\n";
print "----\n" if $verbose;

while (my ($f,$o) = each %file_ops) {
    print "$f : ", ref($o)?"$op_str[$$o[0]] $$o[1]":$op_str[$o], "\n"
	if $verbose;
    next if $dry_run;
    if (ref $o) {
	my ($op,$arg) = @{$o};
	die "unknown op" unless $op == $OP_MOVE;
	move($scan2->{dir}."/$f", $scan2->{dir}."/$arg")
	    or die "failed to move $scan->{dir}/$f -> $scan2->{dir}/$f: $!";
	if (defined $dirlog) {
	    $dirlog->remove($scan2->{dir}."/$f");
	    $dirlog->add($scan2->{dir}."/$arg");
	}

    } elsif ($o == $OP_DEL) {
	unlink $scan2->{dir}."/$f";
	$dirlog->remove($scan2->{dir}."/$f") if defined $dirlog;
    } elsif ($o == $OP_ADD or $o == $OP_REPLACE) {
	copy ($scan->{dir}."/$f", $scan2->{dir}."/$f")
	    or die "failed to copy $scan->{dir}/$f -> $scan2->{dir}/$f: $!";
	copy_timestamp ($f);
	$dirlog->add($scan2->{dir}."/$f") if defined $dirlog;
    } else {
	die  "unknown op $o $f";
    }
}

$dirlog->write() if defined $dirlog;

#rm old dirs
foreach (reverse @{$scan2->{dirs}}) {
    unless (-d $scan->{dir}."/$_") {
	print "rmdir $_\n" if $verbose;
	unless ($dry_run) {
	    rmdir $scan2->{dir}."/$_" 
		or die "failed to remove $scan2->{dir}/$_: $!"
	}
    }
}
#update directory timestamps
copy_timestamp @created_dirs unless $dry_run;

