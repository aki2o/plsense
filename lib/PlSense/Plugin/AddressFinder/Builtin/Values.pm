package PlSense::Plugin::AddressFinder::Builtin::Values;

use parent qw{ PlSense::Plugin::AddressFinder::Builtin };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
use PlSense::Entity::Array;
{
    sub get_builtin_name {
        my ($self) = @_;
        return "values";
    }

    sub find_address_or_entity {
        my ($self, @tokens) = @_;
        my $addr = $self->get_mediator->find_address(@tokens) or return;
        my $entity = PlSense::Entity::Array->new();
        $entity->set_element($addr.".H:*");
        return $entity;
    }
}

1;

__END__
