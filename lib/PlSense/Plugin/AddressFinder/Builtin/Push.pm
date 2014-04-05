package PlSense::Plugin::AddressFinder::Builtin::Push;

use parent qw{ PlSense::Plugin::AddressFinder::Builtin };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
use PlSense::Util;
{
    sub get_builtin_name {
        my ($self) = @_;
        return "push";
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

        if ( ! $self->with_build ) { return; }

        my $mediator = $self->get_mediator;
        my ($addr, @parts);
        TOKEN:
        while ( my $e = shift @tokens ) {
            if ( $e->isa("PPI::Token::Operator") && $e->content eq "," ) {
                $addr = $mediator->find_address(@parts) or return;
                last TOKEN;
            }
            else {
                push @parts, $e;
            }
        }
        if ( ! $addr || $#tokens < 0 ) { return; }

        my $value = $mediator->find_address_or_entity(@tokens) or return;
        substkeeper->add_substitute($addr.".A", $value);
        return;
    }
}

1;

__END__
