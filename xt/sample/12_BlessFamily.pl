#!/usr/bin/perl

use IO::File;
use IO::Socket;
use lib "lib";
use BlessChild;

my $sock = IO::Socket::INET->new();
my $bc = BlessChild->new({ fuga => $sock, });
my $fuga = $bc->get_fuga;
my $io = IO::File->new();
$bc->set_bar($io);


# astart literal method of blessed child class
#my $b2 = BlessChild->
# aend include: new

# astart instance method of blessed child class
#$bc->
# aend equal: can get_bar get_foo get_fuga get_hoge isa new set_bar set_fuga set_hoge

# astart initialized attribute of blessed child class
#$fuga->
# aend include: accept listen

# astart attribute of blessed child class
#$bc->get_bar->
# aend include: ioctl seek fcntl

# astart return super method of blessed child class
#$bc->get_foo->
# aend include: ioctl seek fcntl

# astart initializer of blessed child class
#my $b2 = BlessChild->new({ 
# aend equal: fuga hoge

