package PlSense::Plugin::SubstituteValueFinder::Builtin;

use parent qw{ PlSense::Plugin::SubstituteValueFinder };
use strict;
use warnings;
use Class::Std;
{
    sub get_builtin_name {
        my ($self) = @_;
        return "";
    }
}

1;

__END__
