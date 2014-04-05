package PlSense::Plugin::AddressFinder::Builtin::Shift;

use parent qw{ PlSense::Plugin::AddressFinder::Builtin };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
{
    sub get_builtin_name {
        my ($self) = @_;
        return "shift";
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

        my $mediator = $self->get_mediator;
        my $e = shift @tokens;
        if ( ! $e || ( $e->isa("PPI::Token::Magic") && $e->content eq '@_' ) ) {
            my $mtd = $mediator->get_currentmethod or return;
            $mediator->forward_methodindex;
            return $mtd->get_fullnm."[".$mediator->get_methodindex."]";
        }
        else {
            my $value = $mediator->find_address_or_entity($e, @tokens) or return;
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
        return;
    }
}

1;

__END__
