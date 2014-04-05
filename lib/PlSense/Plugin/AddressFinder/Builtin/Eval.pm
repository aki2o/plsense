package PlSense::Plugin::AddressFinder::Builtin::Eval;

use parent qw{ PlSense::Plugin::AddressFinder::Builtin };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
{
    sub get_builtin_name {
        my ($self) = @_;
        return "eval";
    }

    sub find_address {
        my ($self, @tokens) = @_;
        return $self->find_something(1, @tokens);
    }

    sub find_address_or_entity {
        my ($self, @tokens) = @_;
        return $self->find_something(0, @tokens);
    }

    sub find_something : PRIVATE {
        my ($self, $is_addr, @tokens) = @_;
        my $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Structure::Block") ) { return; }
        my @children = $e->children;
        my $laststmt = pop @children or return;
        if ( ! $laststmt->isa("PPI::Statement") ) { return; }
        return $is_addr ? $self->get_mediator->find_address($laststmt->children)
             :            $self->get_mediator->find_address_or_entity($laststmt->children);
    }
}

1;

__END__
