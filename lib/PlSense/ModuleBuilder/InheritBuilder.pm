package PlSense::ModuleBuilder::InheritBuilder;

use parent qw{ PlSense::ModuleBuilder };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
use PlSense::Configure;
use PlSense::Util;
{
    sub build {
        my ($self, $mdl) = @_;
        my $mdlnm = $mdl->get_name();
        if ( $mdlnm eq "main" ) { return; }
        my $perl = get_config("perl");
        my $libopt = get_config("lib-path") ? "-I'".get_config("lib-path")."'" : "";
        INHERIT:
        foreach my $line ( qx{ $perl $libopt -e 'use $mdlnm; print join "\\n"=>\@${mdlnm}::ISA' 2>/dev/null } ) {
            chomp $line;
            if ( $line !~ m{ ^ [a-zA-Z_][a-zA-Z0-9_:]* $ }xms ) { next INHERIT; }
            my $parent = mdlkeeper->get_module($line);
            if ( ! $parent ) {
                logger->warn("Not found module named [$line]");
                next INHERIT;
            }
            $mdl->push_parent($parent);
            logger->debug("Found parent module of [".$mdl->get_name."] : ".$parent->get_name);
        }
    }
}

1;

__END__

