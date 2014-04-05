package PlSense::ModuleBuilder::PPIBuilder::IncludeStmt;

use strict;
use warnings;
use Class::Std;
use Module::Pluggable instantiate => 'new', search_path => 'PlSense::Plugin::IncludeStmt';
use PlSense::Logger;
use PlSense::Util;
{
    my %plugins_of :ATTR();

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;
        $plugins_of{$ident} = [];
    }

    sub START {
        my ($class, $ident, $arg_ref) = @_;
        my @plugins = $class->plugins();
        PLUGIN:
        foreach my $p ( @plugins ) { push @{$plugins_of{$ident}}, $p; }
    }

    sub build {
        my ($self, $mdl, $stmt) = @_;

        my $mdlnm = $stmt->module or return;

        PLUGIN:
        foreach my $p ( @{$plugins_of{ident $self}} ) {
            $p->include_statement($mdl, $mdlnm, $stmt);
        }

        if ( $stmt->pragma ) { return; }
        if ( $mdl->exist_usingmdl($mdlnm) ) { return; }
        my $incmdl = mdlkeeper->get_module($mdlnm);
        if ( ! $incmdl ) {
            logger->warn("Not found module : $mdlnm");
            return;
        }
        my $filepath = $incmdl->get_filepath;
        if ( ! $filepath || ! -f $filepath ) {
            logger->warn("Not exist module : $mdlnm");
            mdlkeeper->remove_module($incmdl->get_name, $filepath, $incmdl->get_projectnm);
            return;
        }
        logger->debug("Found using module of [".$mdl->get_name."] : ".$incmdl->get_name);
        $mdl->push_usingmdl($incmdl);
        return;
    }
}

1;

__END__
