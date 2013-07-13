package PlSense::Entity::Scalar;

use parent qw{ PlSense::Entity };
use strict;
use warnings;
use Class::Std::Storable;
use PlSense::Logger;
{
    my %value_of :ATTR( :init_arg<value> :default('') );
    sub get_value { my ($self) = @_; return $value_of{ident $self}; }
    sub set_value { my ($self, $value) = @_; $value_of{ident $self} = $value; }

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;
        $class->set_type("scalar");
    }

    sub to_string {
        my $self = shift;
        my $ret = "S<".$self->get_value.">";
        return $ret;
    }

    sub clone {
        my $self = shift;
        return PlSense::Entity::Scalar->new({ value => $value_of{ident $self} });
    }
}

1;

__END__
