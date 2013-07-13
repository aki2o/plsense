#!perl

use IO::File;
use IO::Socket;
use lib "lib";
use ClassStdChild;
use BlessParent;

my $io = IO::File->new();
my $cc = ClassStdChild->new({ attr2 => $io, cattr2 => BlessParent->new(), });
$cc->set_attr3(IO::Socket::INET->new());


# tstart literal method of Class::Std child class
#my $c2 = ClassStdChild->
# tend include: new

# tstart instance method of Class::Std child class
#$cc->
# tend equal: can cf_1 f_1 get_attr1 get_attr_second get_cattr1 get_cattr_second isa set_attr1 set_attr3 set_cattr1 set_cattr3

# tstart super attribute of Class::Std child class
#$cc->get_attr1->
# tend include: ioctl seek fcntl

# tstart super method of Class::Std child class
#$cc->get_attr_second->
# tend include: ioctl seek fcntl

# tstart BlessParent attribute of Class::Std child class
#$cc->get_cattr_second->
# tend equal: can get_fuga get_hoge isa new set_fuga set_hoge

# tstart super call method of Class::Std child class
#$cc->cf_1->
# tend include: accept listen

# tstart initializer of Class::Std child class
#my $c2 = ClassStdChild->new({ 
# tend equal: attr1 attr2 cattr1 cattr2

