package PlSense::Plugin::AddressFinder::Builtin::Pop;

use parent qw{ PlSense::Plugin::AddressFinder::Builtin };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
{
    sub get_builtin_name {
        my ($self) = @_;
        return "pop";
    }

    sub find_address {
        my ($self, @tokens) = @_;
        return $self->find_something(@tokens);
    }

    sub find_address_or_entity {
        my ($self, @tokens) = @_;
        return $self->find_something(@tokens);
    }

    sub find_something : PRIVATE {
        my ($self, @tokens) = @_;
        my $addr = $self->get_mediator->find_address(@tokens) or return;
        return $addr.".A";
    }
}

1;

__END__
