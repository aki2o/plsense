#!perl

use IO::File;
use lib "lib";
use ClassStdParent;

my $io = IO::File->new();
my $c1 = ClassStdParent->new({ attr1 => $io, });
my $attr = $c1->get_attr1;


# tstart include project library package
#use 
# tend include: ClassStdParent

# tstart literal method of Class::Std class
#my $c2 = ClassStdParent->
# tend include: new

# tstart instance method of Class::Std class
#$c1->
# tend equal: can f_1 get_attr1 get_attr_second isa set_attr1 set_attr3

# tstart attribute of Class::Std class
#$attr->
# tend include: ioctl seek fcntl

# tstart initializer of Class::Std class
#my $c2 = ClassStdParent->new({ 
# tend equal: attr1 attr2

