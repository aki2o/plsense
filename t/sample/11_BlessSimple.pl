#!perl

use IO::File;
use lib "lib";
use BlessParent;

my $io = IO::File->new();
my $b1 = BlessParent->new({ hoge => $io, });
my $hoge = $b1->get_hoge;


# tstart literal method of blessed class
#my $b2 = BlessParent->
# tend include: new

# tstart instance method of blessed class
#$b1->
# tend equal: can get_fuga get_hoge isa new set_fuga set_hoge

# tstart initialized attribute of blessed class
#$hoge->
# tend include: ioctl seek fcntl

# tstart initializer of blessed class
#my $b2 = BlessParent->new({ 
# tend equal: hoge

