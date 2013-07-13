#!perl

use IO::File;
use IO::Socket;
use lib "lib";
use BlessChild;

my $sock = IO::Socket::INET->new();
my $bc = BlessChild->new({ fuga => $sock, });
my $fuga = $bc->get_fuga;
my $io = IO::File->new();
$bc->set_bar($io);


# tstart literal method of blessed child class
#my $b2 = BlessChild->
# tend include: new

# tstart instance method of blessed child class
#$bc->
# tend equal: can get_bar get_foo get_fuga get_hoge isa new set_bar set_fuga set_hoge

# tstart initialized attribute of blessed child class
#$fuga->
# tend include: accept listen

# tstart attribute of blessed child class
#$bc->get_bar->
# tend include: ioctl seek fcntl

# tstart return super method of blessed child class
#$bc->get_foo->
# tend include: ioctl seek fcntl

# tstart initializer of blessed child class
#my $b2 = BlessChild->new({ 
# tend equal: fuga hoge

