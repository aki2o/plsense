package ClassStdClone;

use strict;
use warnings;
use Class::Std;
{
    sub clmtd {
    }

    sub clone {
        my $self = shift;
        my $ret = ClassStdClone->new;
        return $ret;
    }
}

1;

__END__
