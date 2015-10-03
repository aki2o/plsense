#!/usr/bin/perl

use IO::File;
use lib "lib";
use ClassStdParent;

my $io = IO::File->new();
my $c1 = ClassStdParent->new({ attr1 => $io, });
my $attr = $c1->get_attr1;


# astart include project library package
#use 
# aend include: ClassStdParent

# astart literal method of Class::Std class
#my $c2 = ClassStdParent->
# aend include: new

# astart instance method of Class::Std class
#$c1->
# aend equal: can f_1 get_attr1 get_attr_second isa set_attr1 set_attr3

# astart attribute of Class::Std class
#$attr->
# aend include: ioctl seek fcntl

# astart initializer of Class::Std class
#my $c2 = ClassStdParent->new({ 
# aend equal: attr1 attr2 cattr1 cattr2

