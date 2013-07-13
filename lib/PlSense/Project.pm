package PlSense::Project;

use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
{
    my %name_of :ATTR( :init_arg<name> );
    sub get_name { my ($self) = @_; return $name_of{ident $self}; }

    my %confpath_of :ATTR( :init_arg<confpath> );
    sub get_confpath { my ($self) = @_; return $confpath_of{ident $self}; }
    sub set_confpath { my ($self, $confpath) = @_; $confpath_of{ident $self} = $confpath; }

    my %libpath_of :ATTR( :default('') );
    sub get_libpath { my ($self) = @_; return $libpath_of{ident $self}; }
    sub set_libpath { my ($self, $libpath) = @_; $libpath_of{ident $self} = $libpath; }

    sub START {
        my ($class, $ident, $arg_ref) = @_;

        my $name = $name_of{$ident} || "";
        if ( ! $name ) {
            logger->error("Name is invalid value : [$name]");
        }
    }
}

1;

__END__
