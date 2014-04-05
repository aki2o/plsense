package PlSense::Plugin::AddressFinder::Builtin::Grep;

use parent qw{ PlSense::Plugin::AddressFinder::Builtin };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
{
    sub get_builtin_name {
        my ($self) = @_;
        return "grep";
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

        my $tok = shift @tokens or return;
        if ( $tok->isa("PPI::Structure::Block") ) {
            return $self->get_mediator->find_address(@tokens);
        }
        elsif ( $tok->isa("PPI::Token::Regexp::Match") ) {
            $tok = shift @tokens or return;
            if ( ! $tok->isa("PPI::Token::Operator") ) { return; }
            return $self->get_mediator->find_address(@tokens);
        }
        else {
            return;
        }
    }
}

1;

__END__
