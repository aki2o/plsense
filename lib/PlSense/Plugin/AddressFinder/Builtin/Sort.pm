package PlSense::Plugin::AddressFinder::Builtin::Sort;

use parent qw{ PlSense::Plugin::AddressFinder::Builtin };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
{
    sub get_builtin_name {
        my ($self) = @_;
        return "sort";
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

        if ( $#tokens >= 0 && $tokens[0]->isa("PPI::Structure::Block") ) {
            my $tok = shift @tokens;
        }
        return $self->get_mediator->find_address(@tokens);
    }
}

1;

__END__
