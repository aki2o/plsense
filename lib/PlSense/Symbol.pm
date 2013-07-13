package PlSense::Symbol;

use strict;
use warnings;
use Class::Std::Storable;
use PlSense::Logger;
{
    my %name_of :ATTR( :init_arg<name> );
    sub get_name { my ($self) = @_; return $name_of{ident $self}; }

    my %type_of :ATTR( :default('') );
    sub set_type { my ($self, $type) = @_; $type_of{ident $self} = $type; }
    sub get_type { my ($self) = @_; return $type_of{ident $self}; }

    my %helptext_of :ATTR( :init_arg<helptext> :default('') );
    sub set_helptext { my ($self, $helptext) = @_; $helptext_of{ident $self} = $helptext; }
    sub get_helptext { my ($self) = @_; return $helptext_of{ident $self}; }

    sub START {
        my ($class, $ident, $arg_ref) = @_;

        my $name = $name_of{$ident} || "";
        if ( ! $name ) {
            logger->error("Name is invalid value : [$name]");
        }
    }

    sub get_fullnm {
        my $self = shift;
        return $self->get_name();
    }
}

1;

__END__
