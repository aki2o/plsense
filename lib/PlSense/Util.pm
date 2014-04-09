package PlSense::Util;

use strict;
use warnings;
use PlSense::Configure;
use Exporter 'import';
our @EXPORT = qw( builtin mdlkeeper addrrouter addrfinder substkeeper substbuilder
                  set_builtin set_mdlkeeper set_addrrouter set_addrfinder set_substkeeper set_substbuilder
                  get_common_options get_common_option_string );
{
    my @confnms = qw{ cachedir port1 port2 port3 loglevel logfile };
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
        my @ret;
        CONF:
        foreach my $confnm ( @confnms ) {
            push @ret, "--".$confnm, get_config($confnm) || "";
        }
        return @ret;
    }

    sub get_common_option_string {
        my $ret = "";
        CONF:
        foreach my $confnm ( @confnms ) {
            $ret .= " --".$confnm." '".( get_config($confnm) || "" )."'";
        }
        return $ret;
    }
}

1;

__END__

