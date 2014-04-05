package PlSense::Plugin::AddressFinder::Builtin::Undef;

use parent qw{ PlSense::Plugin::AddressFinder::Builtin };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
use PlSense::Entity::Null;
{
    sub get_builtin_name {
        my ($self) = @_;
        return "undef";
    }

    sub find_address_or_entity {
        my ($self, @tokens) = @_;
        return PlSense::Entity::Null->new();
    }
}

1;

__END__
