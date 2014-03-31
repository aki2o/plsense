#!/usr/bin/perl

use IO::File;
use lib "lib";
use BlessParent;

my $io = IO::File->new();
my $b1 = BlessParent->new({ hoge => $io, });
my $hoge = $b1->get_hoge;


# astart literal method of blessed class
#my $b2 = BlessParent->
# aend include: new

# astart instance method of blessed class
#$b1->
# aend equal: can get_fuga get_hoge isa new set_fuga set_hoge

# astart initialized attribute of blessed class
#$hoge->
# aend include: ioctl seek fcntl

# astart initializer of blessed class
#my $b2 = BlessParent->new({ 
# aend equal: fuga hoge

