package PlSense::Plugin::AddressFinder::Builtin::Reverse;

use parent qw{ PlSense::Plugin::AddressFinder::Builtin };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
{
    sub get_builtin_name {
        my ($self) = @_;
        return "reverse";
    }

    sub find_address {
        my ($self, @tokens) = @_;
        return $self->get_mediator->find_address(@tokens);
    }

    sub find_address_or_entity {
        my ($self, @tokens) = @_;
        return $self->get_mediator->find_address(@tokens);
    }
}

1;

__END__
