package PlSense::ModuleBuilder::PPIBuilder;

use parent qw{ PlSense::ModuleBuilder };
use strict;
use warnings;
use Class::Std;
use PPI::Lexer;
use Module::Pluggable instantiate => 'new', search_path => 'PlSense::Plugin::PPIBuilder';
use PlSense::Logger;
use PlSense::ModuleBuilder::PPIBuilder::IncludeStmt;
use PlSense::Symbol::Method;
use PlSense::Symbol::Variable;
{
    my %lexer_of :ATTR();
    my %plugins_of :ATTR();
    my %includestmtbuilder_of :ATTR();

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;
        $lexer_of{$ident} = PPI::Lexer->new();
        $plugins_of{$ident} = [];
    }

    sub START {
        my ($class, $ident, $arg_ref) = @_;
        my @plugins = $class->plugins({ builtin => $class->get_builtin,
                                        mdlkeeper => $class->get_mdlkeeper,
                                        substkeeper => $class->get_substkeeper,
                                        substbuilder => $class->get_substbuilder, });
        PLUGIN:
        foreach my $p ( @plugins ) { push @{$plugins_of{$ident}}, $p; }
        $includestmtbuilder_of{$ident} = PlSense::ModuleBuilder::PPIBuilder::IncludeStmt->new({ mdlkeeper => $class->get_mdlkeeper });
    }

    sub build {
        my ($self, $mdl) = @_;
        $self->build_document($mdl, undef, $mdl->get_source);
    }

    sub build_source {
        my ($self, $mdl, $mtd, $source) = @_;
        my $ppi = $lexer_of{ident $self}->lex_source($source) or return;
        $self->build_document($mdl, $mtd, $ppi, 1);
    }

    sub build_document : PRIVATE {
        my ($self, $mdl, $mtd, $ppi, $is_fragment) = @_;

        if ( ! $ppi ) { return; }
        logger->debug("Start build document for [".$mdl->get_name."]\n".$ppi->serialize);

        logger->info("Start find defined method/variable in PPI part");
        $self->build_anything($mdl, $mtd, $ppi->clone, $is_fragment);

        logger->info("Start build source in PPI part");
        $self->get_substbuilder->set_currentmodule($mdl);
        $self->do_plugins_begin($mdl, $ppi);
        $ppi->prune("PPI::Token::Comment");
        $ppi->prune("PPI::Token::Pod");
        $ppi->prune("PPI::Token::Whitespace");
        $self->do_plugins_start($mdl, $ppi);

        my $incstmts = $ppi->find("PPI::Statement::Include");
        if ( $incstmts ) {
            logger->info("Start build include in PPI part");
            INCLUDE:
            foreach my $incstmt ( @{$incstmts} ) {
                $includestmtbuilder_of{ident $self}->build($mdl, $incstmt);
            }
            $ppi->prune("PPI::Statement::Include");
        }

        my $schstmts = $ppi->find("PPI::Statement::Scheduled");
        if ( $schstmts ) {
            logger->info("Start build scheduled in PPI part");
            SCHEDULED:
            foreach my $schstmt ( @{$schstmts} ) {
                my $stmts = $schstmt->find("PPI::Statement") or next SCHEDULED;
                STMT:
                foreach my $stmt ( @{$stmts} ) {
                    if ( $stmt->isa("PPI::Statement::Variable") ) {
                        my $vars = $self->get_variables_from_statement($mdl, undef, $stmt) or next STMT;
                        PLUGIN:
                        foreach my $p ( @{$plugins_of{ident $self}} ) {
                            $p->variable_statement($vars, $stmt);
                        }
                    }
                    else {
                        PLUGIN:
                        foreach my $p ( @{$plugins_of{ident $self}} ) {
                            $p->scheduled_statement($mdl, $schstmt->type, $stmt);
                        }
                    }
                }
            }
            $ppi->prune("PPI::Statement::Scheduled");
        }

        my $mtdstmts = $ppi->find("PPI::Statement::Sub");
        if ( $mtdstmts ) {
            logger->info("Start build sub in PPI part");
            METHOD:
            foreach my $mtdstmt ( @{$mtdstmts} ) {
                my $mtd = $self->get_method_from_statement($mdl, $mtdstmt) or next METHOD;
                $self->get_substbuilder->set_currentmethod($mtd);
                PLUGIN:
                foreach my $p ( @{$plugins_of{ident $self}} ) {
                    $p->sub_statement($mtd, $mtdstmt);
                }
                if ( $mtdstmt->forward ) { next METHOD; }
                my $stmts = $mtdstmt->find("PPI::Statement") or next METHOD;
                STMT:
                foreach my $stmt ( @{$stmts} ) {
                    if ( $stmt->isa("PPI::Statement::Variable") ) {
                        my $vars = $self->get_variables_from_statement($mdl, $mtd, $stmt) or next STMT;
                        PLUGIN:
                        foreach my $p ( @{$plugins_of{ident $self}} ) {
                            $p->variable_statement($vars, $stmt);
                        }
                    }
                    else {
                        PLUGIN:
                        foreach my $p ( @{$plugins_of{ident $self}} ) {
                            $p->other_statement($mdl, $mtd, $stmt);
                        }
                    }
                }
            }
            $ppi->prune("PPI::Statement::Sub");
        }

        my $stmts = $ppi->find("PPI::Statement");
        if ( $stmts ) {
            logger->info("Start build other statement in PPI part");
            if ( $mtd ) {
                $self->get_substbuilder->set_currentmethod($mtd);
            }
            else {
                $self->get_substbuilder->init_currentmethod;
            }
            STMT:
            foreach my $stmt ( @{$stmts} ) {
                if ( $stmt->isa("PPI::Statement::Variable") ) {
                    my $vars = $self->get_variables_from_statement($mdl, $mtd, $stmt) or next STMT;
                    PLUGIN:
                    foreach my $p ( @{$plugins_of{ident $self}} ) {
                        $p->variable_statement($vars, $stmt);
                    }
                }
                else {
                    PLUGIN:
                    foreach my $p ( @{$plugins_of{ident $self}} ) {
                        $p->other_statement($mdl, $mtd, $stmt);
                    }
                }
            }
        }

        $self->get_substbuilder->init_currentmethod;
        $self->do_plugins_end($mdl, $ppi);
    }

    sub build_anything : PRIVATE {
        my ($self, $mdl, $mtd, $ppi, $is_fragment) = @_;
        my $mtdstmts = $ppi->find("PPI::Statement::Sub");
        if ( $mtdstmts ) {
            METHOD:
            foreach my $mtdstmt ( @{$mtdstmts} ) {
                my $mtd = $self->build_method($mdl, $mtdstmt, $is_fragment) or next METHOD;
                my $varstmts = $mtdstmt->find("PPI::Statement::Variable") or next METHOD;
                STMT:
                foreach my $stmt ( @{$varstmts} ) {
                    $self->build_variable($mdl, $mtd, $stmt);
                }
            }
            $ppi->prune("PPI::Statement::Sub");
        }
        my $varstmts = $ppi->find("PPI::Statement::Variable") or return;
        STMT:
        foreach my $stmt ( @{$varstmts} ) {
            $self->build_variable($mdl, $mtd, $stmt);
        }
    }

    sub build_variable : PRIVATE {
        my ($self, $mdl, $mtd, $stmt) = @_;
        logger->info("Found variable statement : ".$stmt->content);
        if ( $stmt->type ne "my" && $stmt->type ne "our" ) { return; }
        SYMBOL:
        foreach my $varnm ( $stmt->symbols ) {
            my $var = $mtd && $mtd->exist_variable($varnm) ? $mtd->get_variable($varnm)
                    : $mdl->exist_member($varnm)           ? $mdl->get_member($varnm)
                    :                                        PlSense::Symbol::Variable->new({ name => "$varnm",
                                                                                              lexical => $stmt->type eq "our" ? 0 : 1,
                                                                                              belong => $mtd && $stmt->type eq "my" ? $mtd : $mdl, });
            $var->set_importive(0);
        }
    }

    sub get_variables_from_statement : PRIVATE {
        my ($self, $mdl, $mtd, $stmt) = @_;
        if ( $stmt->type ne "my" && $stmt->type ne "our" ) { return; }
        my @vars;
        SYMBOL:
        foreach my $varnm ( $stmt->symbols ) {
            my $var = $mtd && $mtd->exist_variable($varnm) ? $mtd->get_variable($varnm)
                    : $mdl->exist_member($varnm)           ? $mdl->get_member($varnm)
                    :                                        undef;
            if ( ! $var ) { return; }
            push @vars, $var;
        }
        return \@vars;
    }

    sub build_method : PRIVATE {
        my ($self, $mdl, $mtdstmt, $is_fragment) = @_;
        my $mtdnm = $mtdstmt->name();
        logger->info("Found method statement : $mtdnm");
        my $mtd = $mdl->exist_method($mtdnm) ? $mdl->get_method($mtdnm)
                :                              PlSense::Symbol::Method->new({ name => "$mtdnm", module => $mdl, publicly => 1 });
        $mtd->set_importive(0);
        if ( $mtdstmt->reserved ) { $mtd->set_reserved(1); }

        my @tokens = $mtdstmt->children;
        METHOD_TOKEN:
        foreach my $tok ( @tokens ) {
            if ( ! $tok || ! $tok->isa("PPI::Token::Attribute") ) { next METHOD_TOKEN; }
            my $attr = { content => $tok->content,
                         identifier => $tok->identifier,
                         parameters => $tok->parameters, };
            $mtd->set_attribute($attr);
            last METHOD_TOKEN;
        }

        if ( ! $is_fragment ) {
            $mtd->set_linenumber($mtdstmt->line_number);
            $mtd->set_colnumber($mtdstmt->column_number);
        }

        return $mtd;
    }

    sub get_method_from_statement : PRIVATE {
        my ($self, $mdl, $mtdstmt) = @_;
        my $mtdnm = $mtdstmt->name();
        return $mdl->exist_method($mtdnm) ? $mdl->get_method($mtdnm) : undef;
    }

    sub do_plugins_begin : PRIVATE {
        my ($self, $mdl, $ppi) = @_;
        PLUGIN:
        foreach my $p ( @{$plugins_of{ident $self}} ) { $p->begin($mdl, $ppi); }
    }

    sub do_plugins_start : PRIVATE {
        my ($self, $mdl, $ppi) = @_;
        PLUGIN:
        foreach my $p ( @{$plugins_of{ident $self}} ) { $p->start($mdl, $ppi); }
    }

    sub do_plugins_end : PRIVATE {
        my ($self, $mdl, $ppi) = @_;
        PLUGIN:
        foreach my $p ( @{$plugins_of{ident $self}} ) { $p->end($mdl, $ppi); }
    }
}

1;

__END__
