package PlSense::Util;

use strict;
use warnings;
use PlSense::Configure;
use Exporter 'import';
our @EXPORT = qw( builtin mdlkeeper addrrouter addrfinder substkeeper substbuilder
                  set_builtin set_mdlkeeper set_addrrouter set_addrfinder set_substkeeper set_substbuilder
                  reset_all_util get_common_option );
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

    sub reset_all_util {
        undef $builtin;
        undef $mdlkeeper;
        undef $addrrouter;
        undef $addrfinder;
        undef $substkeeper;
        undef $substbuilder;
    }

    sub get_common_option {
        my $ret = "--cachedir '".(get_config("cachedir") || "")."'";
        $ret .= " --loglevel '".(get_config("loglevel") || "")."'";
        $ret .= " --logfile '".(get_config("logfile") || "")."'";
        $ret .= " --port1 ".get_config("port1");
        $ret .= " --port2 ".get_config("port2");
        $ret .= " --port3 ".get_config("port3");
        return $ret;
    }
}

1;

__END__

