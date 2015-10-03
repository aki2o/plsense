package ClassStdParent;

use strict;
use warnings;
use Class::Std;
use FindBin;
use File::Basename;
{
    my %attr1_of :ATTR( :name<attr1> );
    my %attr2_of :ATTR( :init_arg('attr2') :get<attr_second> :default(undef) );
    my %attr3_of :ATTR( :set => 'attr3' :default('') );

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;

        # astart own instance of BUILD in Class::Std
        #$class->
        # aend equal: can f_1 f_2 f_3 get_attr1 get_attr_second isa set_attr1 set_attr3

        # astart own initializer of BUILD in Class::Std
        #$arg_ref->{
        # aend equal: attr1 attr2
    }

    sub START {
        my ($class, $ident, $arg_ref) = @_;

        # astart own instance of START in Class::Std
        #$class->
        # aend equal: can f_1 f_2 f_3 get_attr1 get_attr_second isa set_attr1 set_attr3

        # astart own initializer of START in Class::Std
        #$arg_ref->{
        # aend equal: attr1 attr2

        # astart own scalar of START in Class::Std
        #$
        # aend include: attr1_of attr2_of attr3_of class ident arg_ref

        # astart own hash of START in Class::Std
        #%
        # aend include: attr1_of attr2_of attr3_of
    }

    sub f_1 {
        my ($self) = @_;

        # astart own instance of own method in Class::Std
        #$self->
        # aend equal: can f_1 f_2 f_3 get_attr1 get_attr_second isa set_attr1 set_attr3

        # astart own scalar of own method in Class::Std
        #$
        # aend include: attr1_of attr2_of attr3_of self
        # aend exclude: class ident arg_ref

        return $self->get_attr1;
    }

    sub f_2 : RESTRICTED {
        my $self = shift;

        # astart instance of own member in Class::Std
        #$attr1_of{ident $self}->
        # aend include: ioctl seek fcntl

        return $attr3_of{ident $self};
    }

    sub f_3 : PRIVATE {
        my $self = shift;
    }
}

1;

__END__
