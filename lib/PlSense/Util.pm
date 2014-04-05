package PlSense::Util;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw( builtin mdlkeeper addrrouter addrfinder substkeeper substbuilder
                  set_builtin set_mdlkeeper set_addrrouter set_addrfinder set_substkeeper set_substbuilder );
{
    my $builtin;
    my $mdlkeeper;
    my $addrrouter;
    my $addrfinder;
    my $substkeeper;
    my $substbuilder;

    sub builtin { return $builtin; }
    sub mdlkeeper { return $mdlkeeper; }
    sub addrrouter { return $addrrouter; }
    sub addrfinder { return $addrfinder; }
    sub substkeeper { return $substkeeper; }
    sub substbuilder { return $substbuilder; }

    sub set_builtin { $builtin = shift; }
    sub set_mdlkeeper { $mdlkeeper = shift; }
    sub set_addrrouter { $addrrouter = shift; }
    sub set_addrfinder { $addrfinder = shift; }
    sub set_substkeeper { $substkeeper = shift; }
    sub set_substbuilder { $substbuilder = shift; }
}

1;

__END__

