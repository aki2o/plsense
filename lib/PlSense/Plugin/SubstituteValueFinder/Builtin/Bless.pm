package PlSense::Plugin::SubstituteValueFinder::Builtin::Bless;

use parent qw{ PlSense::Plugin::SubstituteValueFinder::Builtin };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
{
    sub get_builtin_name {
        my ($self) = @_;
        return "bless";
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
        my $value = $mediator->find_address_or_entity(@tokens) or return;
        my $vtype = eval { $value->get_type } || "";
        if ( $vtype ) {
            if ( $vtype ne 'reference' ) { return; }
            $value = $value->get_entity;
        }
        else {
            $value .= ".R";
        }

        my $mdl = $mediator->get_currentmodule;
        $mediator->get_substkeeper->add_substitute('&'.$mdl->get_name.'::BLESS.R', $value, 1);
        return;
    }
}

1;

__END__
