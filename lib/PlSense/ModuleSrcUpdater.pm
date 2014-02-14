package PlSense::ModuleSrcUpdater;

use strict;
use warnings;
use Class::Std;
use PPI::Document;
use PlSense::Logger;
use PlSense::ModuleBuilder::PPIBuilder::IncludeStmt;
use PlSense::Symbol::Module;
{
    my %mdlkeeper_of :ATTR( :init_arg<mdlkeeper> );
    sub get_mdlkeeper : RESTRICTED { my ($self) = @_; return $mdlkeeper_of{ident $self}; }

    my %includestmtbuilder_of :ATTR();

    sub START {
        my ($class, $ident, $arg_ref) = @_;
        $includestmtbuilder_of{$ident} = PlSense::ModuleBuilder::PPIBuilder::IncludeStmt->new({ mdlkeeper => $class->get_mdlkeeper });
    }

    sub update_or_create_modules {
        my ($self, $filepath, $projectnm) = @_;
        my %foundmdl_is;

        if ( ! -f $filepath ) {
            logger->error("Not exist file[$filepath]");
            return ();
        }
        my @attr = stat $filepath;
        my $lastmodified = $attr[9];

        my $mdlkeeper = $self->get_mdlkeeper;
        my $currmdl = $mdlkeeper->get_module("main", $filepath);
        if ( ! $currmdl ) {
            $currmdl = PlSense::Symbol::Module->new({ name => "main",
                                                      filepath => $filepath,
                                                      projectnm => $projectnm,
                                                      lastmodified => $lastmodified,
                                                      linenumber => 1,
                                                      colnumber => 1, });
            logger->notice("New module [".$currmdl->get_name."] in [".$currmdl->get_filepath."] belong [".$currmdl->get_projectnm."]");
            $mdlkeeper->store_module($currmdl);
        }
        $currmdl->reset_all($lastmodified);
        $foundmdl_is{$currmdl->get_name} = $currmdl;

        logger->notice("Start get PPI::Document of module from [".$filepath."]");
        my $doc = PPI::Document->new( $filepath, readonly => 1 );
        if ( ! $doc ) {
            logger->warn("Can't get PPI::Document from [$filepath]");
            return ($currmdl);
        }

        my $mainmdl = $currmdl;
        TOPSTMT:
        foreach my $e ( $doc->children ) {

            # Get current package
            if ( $e->isa("PPI::Statement::Package") ) {

                my $mdlnm = "".$e->namespace."";
                if ( $mdlnm eq "main" ) {
                    $currmdl = $mainmdl;
                }
                elsif ( ! exists $foundmdl_is{$mdlnm} ) {
                    my $mdl = $mdlkeeper->get_module($mdlnm);
                    if ( ! $mdl ) {
                        $mdl = PlSense::Symbol::Module->new({ name => $mdlnm,
                                                              filepath => $filepath,
                                                              projectnm => $projectnm,
                                                              lastmodified => $lastmodified });
                        logger->notice("New module [".$mdl->get_name."] in [".$mdl->get_filepath."] belong [".$mdl->get_projectnm."]");
                        $mdlkeeper->store_module($mdl);
                    }
                    $mdl->reset_all($lastmodified);
                    $foundmdl_is{$mdlnm} = $mdl;
                    logger->debug("Found bundle module of [".$mainmdl->get_name."] : ".$mdl->get_name);
                    $mainmdl->push_bundlemdl($mdl);
                }
                $currmdl = $foundmdl_is{$mdlnm};
                $currmdl->set_linenumber($e->line_number);
                $currmdl->set_colnumber($e->column_number);

            }

            elsif ( $currmdl && $e->isa("PPI::Element") ) {
                my $currdoc = $currmdl->get_source;
                if ( ! $currdoc ) {
                    $currdoc = PPI::Document->new;
                    $currmdl->set_source($currdoc);
                }
                if ( ! $currdoc->add_element($e->clone) ) {
                    logger->error("Failed add source to ".$currmdl->get_name);
                }
            }

        }

        return values %foundmdl_is;
    }
}

1;

__END__
