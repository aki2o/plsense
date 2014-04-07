package PlSense::Entity;

use strict;
use warnings;
use Class::Std::Fast::Storable;
use PlSense::Logger;
{
    my %type_of :ATTR();
    sub set_type : RESTRICTED {
        my ($self, $type) = @_;
        $type_of{ident $self} = $type;
    }
    sub get_type { my ($self) = @_; return $type_of{ident $self}; }

    sub START {
        my ($class, $ident, $arg_ref) = @_;
        my $type = $type_of{$ident} || "";
        if ( $type ne "null"
          && $type ne "scalar"
          && $type ne "array"
          && $type ne "hash"
          && $type ne "reference"
          && $type ne "instance" ) {
            logger->error("Invalid type[$type]");
        }
    }

    sub to_string {
        my $self = shift;
        return "";
    }

    sub clone {
        my $self = shift;
        return;
    }
}

1;

__END__
