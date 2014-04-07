package PlSense::Entity::Null;

use parent qw{ PlSense::Entity };
use strict;
use warnings;
use Class::Std::Storable;
use PlSense::Logger;
{
    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;
        $class->set_type("null");
    }

    sub to_string {
        my $self = shift;
        my $ret = "NULL";
        return $ret;
    }

    sub clone {
        my $self = shift;
        return PlSense::Entity::Null->new();
    }
}

1;

__END__
