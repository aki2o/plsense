package PlSense::Plugin::AddressFinder::Ext::Uniq;

use parent qw{ PlSense::Plugin::AddressFinder::Ext };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
{
    sub get_method_name {
        my ($self) = @_;
        return "uniq";
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

        my $mdl = $self->get_mediator->get_currentmodule;
        if ( ! $mdl->exist_usingmdl("List::MoreUtils") &&
             ! $mdl->exist_usingmdl("List::AllUtils") ) { return; }

        return $self->get_mediator->find_address(@tokens);
    }
}

1;

__END__
