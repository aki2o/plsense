package PlSense::Util;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw( builtin mdlkeeper addrrouter substkeeper substbuilder
                  set_builtin set_mdlkeeper set_addrrouter set_substkeeper set_substbuilder );
{
    my $builtin;
    my $mdlkeeper;
    my $addrrouter;
    my $substkeeper;
    my $substbuilder;

    sub builtin { return $builtin; }
    sub mdlkeeper { return $mdlkeeper; }
    sub addrrouter { return $addrrouter; }
    sub substkeeper { return $substkeeper; }
    sub substbuilder { return $substbuilder; }

    sub set_builtin { $builtin = shift; }
    sub set_mdlkeeper { $mdlkeeper = shift; }
    sub set_addrrouter { $addrrouter = shift; }
    sub set_substkeeper { $substkeeper = shift; }
    sub set_substbuilder { $substbuilder = shift; }
}

1;

__END__

