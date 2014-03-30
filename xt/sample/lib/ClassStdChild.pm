package ClassStdChild;

use parent qw{ ClassStdParent };
use strict;
use warnings;
use Class::Std;
{
    my %cattr1_of :ATTR( :name<cattr1> );
    my %cattr2_of :ATTR( :init_arg('cattr2') :get<cattr_second> :default(undef) );
    my %cattr3_of :ATTR( :set => 'cattr3' :default('') );

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;

        # astart own instance of BUILD in Class::Std child
        #$class->
        # aend equal: SUPER::f_1 SUPER::f_2 SUPER::get_attr1 SUPER::get_attr_second SUPER::set_attr1 SUPER::set_attr3 can cf_1 f_1 f_2 get_attr1 get_attr_second get_cattr1 get_cattr_second isa set_attr1 set_attr3 set_cattr1 set_cattr3

        # astart own initializer of BUILD in Class::Std child
        #$arg_ref->{
        # aend equal: attr1 attr2 cattr1 cattr2

        # astart own scalar of BUILD in Class::Std child
        #$
        # aend include: cattr1_of cattr2_of cattr3_of class ident arg_ref
        # aend exclude: attr1_of attr2_of attr3_of

        # astart own hash of BUILD in Class::Std child
        #%
        # aend include: cattr1_of cattr2_of cattr3_of
        # aend exclude: attr1_of attr2_of attr3_of
    }

    sub cf_1 {
        my ($self) = @_;

        # astart own instance of own method in Class::Std child
        #$self->
        # aend equal: SUPER::f_1 SUPER::f_2 SUPER::get_attr1 SUPER::get_attr_second SUPER::set_attr1 SUPER::set_attr3 can cf_1 f_1 f_2 get_attr1 get_attr_second get_cattr1 get_cattr_second isa set_attr1 set_attr3 set_cattr1 set_cattr3

        # astart own scalar of own method in Class::Std child
        #$
        # aend include: cattr1_of cattr2_of cattr3_of self
        # aend exclude: attr1_of attr2_of attr3_of class ident arg_ref

        # astart super method in Class::Std child
        #$self->SUPER::f_1->
        # aend include: ioctl seek fcntl

        # mstart super method of Class::Std child class
        #$self->SUPER::f_1
        # mend ^ NAME: \s f_1 $
        # mend ^ FILE: \s .+/ClassStdParent\.pm $

        return $self->f_2;
    }

    # astart define inherite method in Class::Std child
    #sub 
    # aend equal: f_1 f_2 get_attr1 get_attr_second set_attr1 set_attr3

}

1;

__END__
