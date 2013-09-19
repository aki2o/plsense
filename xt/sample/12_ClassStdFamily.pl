#!/usr/bin/perl

use IO::File;
use IO::Socket;
use lib "lib";
use ClassStdChild;
use BlessParent;

my $io = IO::File->new();
my $cc = ClassStdChild->new({ attr2 => $io, cattr2 => BlessParent->new(), });
$cc->set_attr3(IO::Socket::INET->new());


# astart literal method of Class::Std child class
#my $c2 = ClassStdChild->
# aend include: new

# astart instance method of Class::Std child class
#$cc->
# aend equal: can cf_1 f_1 get_attr1 get_attr_second get_cattr1 get_cattr_second isa set_attr1 set_attr3 set_cattr1 set_cattr3

# astart super attribute of Class::Std child class
#$cc->get_attr1->
# aend include: ioctl seek fcntl

# astart super method of Class::Std child class
#$cc->get_attr_second->
# aend include: ioctl seek fcntl

# astart BlessParent attribute of Class::Std child class
#$cc->get_cattr_second->
# aend equal: can get_fuga get_hoge isa new set_fuga set_hoge

# astart super call method of Class::Std child class
#$cc->cf_1->
# aend include: accept listen

# astart initializer of Class::Std child class
#my $c2 = ClassStdChild->new({ 
# aend equal: attr1 attr2 cattr1 cattr2


# hstart instance method of Class::Std child class
#$cc->get_cattr1
# hend ^ get_cattr1 \s is \s Method \s of \s ClassStdChild

# hstart instance method of Class::Std parent class
#$cc->get_attr1
# hend ^ get_attr1 \s is \s Method \s of \s ClassStdParent


# mstart instance method of Class::Std child class
#$cc->get_cattr1
# mend ^ NAME: \s get_cattr1 $
# mend ^ RETURN: \s NoIdent \s As \s Unknown $
# mend ^ FILE: \s .+ /ClassStdChild.pm $
# mend ^ LINE: \s 0 $
# mend ^ COL: \s 0 $

# mstart instance method of Class::Std parent class
#$cc->get_attr1
# mend ^ NAME: \s get_attr1 $
# mend ^ RETURN: \s NoIdent \s As \s IO::File $
# mend ^ FILE: \s .+ /ClassStdParent.pm $
# mend ^ LINE: \s 0 $
# mend ^ COL: \s 0 $


