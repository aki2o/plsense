#!/usr/bin/perl

use List::Util qw{ first };
use IO::File;

my $io = IO::File->new();

my @arrio;
push @arrio, $io;

my $fst = first { $_ && $_->isa("IO::File") } @arrio;
# astart first
#$fst->
# aend include: ioctl seek fcntl

