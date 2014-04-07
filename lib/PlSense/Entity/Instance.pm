package PlSense::Entity::Instance;

use parent qw{ PlSense::Entity };
use strict;
use warnings;
use Class::Std::Storable;
use PlSense::Logger;
{
    my %modulenm_of :ATTR( :init_arg<modulenm> :default('') );
    sub set_modulenm { my ($self, $modulenm) = @_; $modulenm_of{ident $self} = $modulenm; }
    sub get_modulenm { my ($self) = @_; return $modulenm_of{ident $self}; }

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;
        $class->set_type("instance");
    }

    sub to_string {
        my $self = shift;
        my $ret = "I<";
        $ret .= $self->get_modulenm ? $self->get_modulenm : "";
        $ret .= ">";
        return $ret;
    }

    sub clone {
        my $self = shift;
        return PlSense::Entity::Instance->new({ modulenm => $modulenm_of{ident $self} });
    }
}

1;

__END__
