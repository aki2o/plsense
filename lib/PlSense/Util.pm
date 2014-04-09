package PlSense::Util;

use strict;
use warnings;
use PlSense::Configure;
use Exporter 'import';
our @EXPORT = qw( builtin mdlkeeper addrrouter addrfinder substkeeper substbuilder
                  set_builtin set_mdlkeeper set_addrrouter set_addrfinder set_substkeeper set_substbuilder
                  get_common_options );
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

    sub get_common_options {
        return ( "--cachedir", get_config("cachedir"),
                 "--loglevel", get_config("loglevel"),
                 "--logfile",  get_config("logfile"),
                 "--port1",    get_config("port1"),
                 "--port2",    get_config("port2"),
                 "--port3",    get_config("port3") );
    }
}

1;

__END__

