package PlSense::ModuleBuilder::XrefBuilder;

use parent qw{ PlSense::ModuleBuilder };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
use PlSense::Configure;
use PlSense::Util;
use PlSense::Symbol::Method;
use PlSense::Symbol::Variable;
{
    sub build {
        my ($self, $mdl) = @_;
        my $mdlnm = $mdl->get_name();
        my $currpkg = "";
        my $currmtd = "";
        my $perl = get_config("perl");
        my $libopt = get_config("lib-path") ? "-I'".get_config("lib-path")."'" : "";
        my $cmdstr = $mdlnm eq "main" ? "'".$mdl->get_filepath."'" : "-e 'use $mdlnm'";
        PARSE_XREF:
        foreach my $line ( qx{ $perl $libopt -MO=Xref $cmdstr 2>/dev/null } ) {
            chomp $line;
            if ( $line =~ m{ ^ \s+ Subroutine \s+ (.+) $ }xms ) {
                my @pkgtree = split m{ :: }xms, $1;
                my $mtdnm = pop @pkgtree || "";
                if ( $mtdnm eq "(definitions)" ) {
                    $currpkg = "";
                    $currmtd = "";
                }
                elsif ( $mtdnm =~ m{ ^ [a-zA-Z_][a-zA-Z0-9_]* $ }xms ) {
                    $currpkg = join "::", @pkgtree;
                    $currmtd = $mtdnm;
                }
                else {
                    $currmtd = "";
                }
            }
            elsif ( $line =~ m{ ^ \s+ Package \s+ ([a-zA-Z_][a-zA-Z0-9_:]*) $ }xms ) {
                $currpkg = $1;
            }
            elsif ( $line =~ m{ ^ \s+ (\$|\@|\%|\&) ([a-zA-Z_][a-zA-Z_0-9]*) \s+ (.+) $ }xms ) {
                my ($idtype, $idvalue, $etcinfo) = ($1, $2, $3);
                if ( $currpkg eq $mdlnm ) {
                    $self->build_parts($mdl, $currmtd, $idtype, $idvalue, $etcinfo);
                }
            }
        }
    }

    sub build_parts : PRIVATE {
        my ($self, $mdl, $mtdnm, $idtype, $idvalue, $etcinfo) = @_;
        my $mtd;
        if ( $mtdnm ne "" ) {
            my $reserved = $mtdnm eq uc($mtdnm) ? 1 : 0;
            my $publicly = $mtdnm !~ m{ ^ _ }xms && ! $reserved ? 1 : 0;
            $mtd = $mdl->exist_method($mtdnm) ? $mdl->get_method($mtdnm)
                 :                              PlSense::Symbol::Method->new({ name => $mtdnm,
                                                                               module => $mdl,
                                                                               publicly => $publicly,
                                                                               importive => 1,
                                                                               reserved => $reserved, });
        }
        if ( $idtype eq '&' ) {
            if ( ! $mdl->exist_method($idvalue) ) {
                my $reserved = $idvalue eq uc($idvalue) ? 1 : 0;
                my $publicly = $idvalue !~ m{ ^ _ }xms && ! $reserved ? 1 : 0;
                my $mtd = PlSense::Symbol::Method->new({ name => $idvalue,
                                                         module => $mdl,
                                                         publicly => $publicly,
                                                         importive => 1,
                                                         reserved => $reserved, });
            }
        }
        elsif ( ! builtin->exist_variable($idtype.$idvalue) ) {
            my $varnm = $idtype.$idvalue;
            my $lexical = $etcinfo =~ m{ i }xms ? 1 : 0;
            my $var;
            if ( $lexical && $mtd ) {
                $var = $mtd->exist_variable($varnm) ? $mtd->get_variable($varnm)
                     :                                PlSense::Symbol::Variable->new({ name => $varnm,
                                                                                       belong => $mtd,
                                                                                       importive => $lexical ? 0 : 1 });
                $var->set_lexical($lexical);
            }
            else {
                $var = $mdl->exist_member($varnm) ? $mdl->get_member($varnm)
                     :                              PlSense::Symbol::Variable->new({ name => $varnm,
                                                                                     belong => $mdl,
                                                                                     importive => $lexical ? 0 : 1 });
                $var->set_lexical($lexical);
            }
        }
    }
}

1;

__END__

