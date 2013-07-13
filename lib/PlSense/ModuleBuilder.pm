package PlSense::ModuleBuilder;

use strict;
use warnings;
use Class::Std;
{
    my %builtin_of :ATTR( :init_arg<builtin> );
    sub get_builtin : RESTRICTED { my ($self) = @_; return $builtin_of{ident $self}; }

    my %mdlkeeper_of :ATTR( :init_arg<mdlkeeper> );
    sub get_mdlkeeper : RESTRICTED { my ($self) = @_; return $mdlkeeper_of{ident $self}; }

    my %substkeeper_of :ATTR( :init_arg<substkeeper> );
    sub get_substkeeper : RESTRICTED { my ($self) = @_; return $substkeeper_of{ident $self}; }

    my %substbuilder_of :ATTR( :init_arg<substbuilder> );
    sub get_substbuilder : RESTRICTED { my ($self) = @_; return $substbuilder_of{ident $self}; }

    my %libpath_of :ATTR( :init_arg<libpath> :default('') );
    sub get_libpath : RESTRICTED { my ($self) = @_; return $libpath_of{ident $self}; }

    sub build {
        my ($self, $mdl) = @_;
    }
}

1;

__END__

