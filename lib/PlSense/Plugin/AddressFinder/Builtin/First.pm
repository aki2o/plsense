package PlSense::Plugin::AddressFinder::Builtin::First;

use parent qw{ PlSense::Plugin::AddressFinder::Builtin };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
{
    sub get_builtin_name {
        my ($self) = @_;
        return "first";
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

        my $tok = shift @tokens or return;
        if ( ! $tok->isa("PPI::Structure::Block") ) { return; }

        my $value = $self->get_mediator->find_address_or_entity(@tokens) or return;
        if ( eval { $value->isa("PlSense::Entity") } ) {
            if ( ! $value->isa("PlSense::Entity::Array") ) { return; }
            my $el = $value->get_element;
            if ( $el ) {
                if ( $is_addr && eval { $el->isa("PlSense::Entity") } ) { return; }
                return $el;
            }
            if ( $value->count_address > 0 ) { return $value->get_address(1).".A"; }
        }
        else {
            return $value.".A";
        }
    }
}

1;

__END__
