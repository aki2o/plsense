#!/usr/bin/perl

use List::MoreUtils qw{ uniq };
use IO::File;

my $io = IO::File->new();

my @arrio;
push @arrio, $io;

my @uarrio = uniq @arrio;
# astart uniq
#$uarrio[0]->
# aend include: ioctl seek fcntl

my @uarrio2 = uniq(@arrio);
# astart uniq with brace
#$uarrio2[0]->
# aend include: ioctl seek fcntl

