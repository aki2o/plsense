package PlSense::ModuleBuilder;

use strict;
use warnings;
use Class::Std;
{
    my %substkeeper_of :ATTR( :init_arg<substkeeper> );
    sub get_substkeeper : RESTRICTED { my ($self) = @_; return $substkeeper_of{ident $self}; }

    my %substbuilder_of :ATTR( :init_arg<substbuilder> );
    sub get_substbuilder : RESTRICTED { my ($self) = @_; return $substbuilder_of{ident $self}; }

    sub build {
        my ($self, $mdl) = @_;
    }
}

1;

__END__

