package PlSense::Plugin::AddressFinder;

use strict;
use warnings;
use Class::Std;
{
    my %with_build_is :ATTR( :init_arg<with_build> );
    sub with_build : RESTRICTED { my ($self) = @_; return $with_build_is{ident $self} ? 1 : 0; }

    my %mediator_of :ATTR( :init_arg<mediator> );
    sub get_mediator : RESTRICTED { my ($self) = @_; return $mediator_of{ident $self}; }

    sub find_address {
        my ($self, @tokens) = @_;
        return;
    }

    sub find_address_or_entity {
        my ($self, @tokens) = @_;
        return;
    }
}

1;

__END__
