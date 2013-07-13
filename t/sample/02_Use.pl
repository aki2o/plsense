#!/usr/bin/perl

use IO::File;
use FindBin;
use File::Basename;
use File::Spec;
use List::AllUtils qw{ min max };

my $scalar1 = IO::File->new();
my @arr1;
push @arr1, IO::File->new();
my %hash1;
$hash1{key1} = IO::File->new();
$hash1{key2} = \@arr1;
our ($scalar2, @arr2, %hash2);
$scalar2 = \%hash1;


# tstart select parent module by base
#use base qw{ 
# tend include: Exporter Getopt::Long
# tend exclude: grep _ ARGV ENV

# tstart select parent module by parent
#use parent qw{ 
# tend include: Exporter Getopt::Long
# tend exclude: grep _ ARGV ENV

# tstart select import
#use List::AllUtils qw{ 
# tend include: first all uniq :all
# tend exclude: Exporter grep _ ARGV ENV

# tstart select import has input
#use List::AllUtils qw{ uniq 
# tend include: first all :all
# tend exclude: uniq

# tstart own and import scalar
#$
# tend include: scalar1 arr1 hash1 scalar2 arr2 hash2 FindBin::Bin

# tstart own array
#@
# tend include: arr1 arr2

# tstart own hash
#%
# tend include: hash1 hash2

# tstart defined hash key
#$hash1{
# tend equal: key1 key2

# tstart defined hash key of reference
#$scalar2->{
# tend equal: key1 key2

# tstart defined hash key has word
#$hash1{k
# tend include: key1 key2 kill keys

# tstart defined hash key of reference has word
#$scalar2->{k
# tend include: key1 key2 kill keys

# tstart on maybe function word include import
#m
# tend include: map min max

# tstart included module literal method
#File::Spec->
# tend include: rel2abs abs2rel
# tend exclude: grep

# tstart call instance method of scalar
#$scalar1->
# tend include: ioctl seek fcntl

# tstart call instance method of array
#$arr1[0]->
# tend include: ioctl seek fcntl

# tstart call instance method of hash
#$hash1{key1}->
# tend include: ioctl seek fcntl

# tstart call instance method of array reference
#$hash1{key2}->[0]->
# tend include: ioctl seek fcntl

# tstart call instance method of hash reference
#$scalar2->{key1}->
# tend include: ioctl seek fcntl



