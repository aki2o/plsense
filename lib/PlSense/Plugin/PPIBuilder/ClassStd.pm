package PlSense::Plugin::PPIBuilder::ClassStd;

use parent qw{ PlSense::Plugin::PPIBuilder };
use strict;
use warnings;
use Class::Std;
use List::AllUtils qw{ first };
use PlSense::Logger;
use PlSense::Util;
use PlSense::Symbol::Method;
use PlSense::Entity::Reference;
use PlSense::Entity::Hash;
use PlSense::Entity::Null;
{
    sub end {
        my ($self, $mdl, $ppi) = @_;
        if ( ! $mdl->exist_usingmdl("Class::Std") &&
             ! $mdl->exist_usingmdl("Class::Std::Storable") &&
             ! $mdl->exist_usingmdl("Class::Std::Fast::Storable") ) { return; }

        substkeeper->add_substitute("&".$mdl->get_fullnm."::BUILD[3]", "&".$mdl->get_fullnm."::new[2]", 1);
        substkeeper->add_substitute("&".$mdl->get_fullnm."::START[3]", "&".$mdl->get_fullnm."::new[2]", 1);
    }

    sub sub_statement {
        my ($self, $mtd, $stmt) = @_;

        my $mdl = $mtd->get_module or return;
        if ( ! $mdl->exist_usingmdl("Class::Std") &&
             ! $mdl->exist_usingmdl("Class::Std::Storable") &&
             ! $mdl->exist_usingmdl("Class::Std::Fast::Storable") ) { return; }

        my $attr = $mtd->get_attribute or return;
        if ( $attr->{content} eq 'PRIVATE' ) {
            $mtd->set_publicly(0);
            $mtd->set_privately(1);
        }
        elsif ( $attr->{content} eq 'RESTRICTED' ) {
            $mtd->set_publicly(0);
        }
    }

    sub variable_statement {
        my ($self, $vars, $stmt) = @_;

        if ( $#{$vars} != 0 ) { return; }
        my $var = @{$vars}[0];
        my $mdl = $var->get_belong or return;
        if ( ! $mdl->isa("PlSense::Symbol::Module") ) { return; }
        if ( ! $mdl->exist_usingmdl("Class::Std") &&
             ! $mdl->exist_usingmdl("Class::Std::Storable") &&
             ! $mdl->exist_usingmdl("Class::Std::Fast::Storable") ) { return; }

        my @tokens = $stmt->children;
        my $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Token::Word") || $e->content ne "my" ) { return; }
        $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Token::Symbol") ) { return; }
        $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Token::Operator") || $e->content ne ':' ) { return; }
        $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Token::Word") || $e->content ne 'ATTR' ) { return; }
        $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Structure::List") ) { return; }
        @tokens = $e->children;
        $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Statement::Expression") ) { return; }

        my $attrtext = "".$e->content."";
        logger->info("Found Attr of Class::Std for [".$var->get_fullnm."] : ".$attrtext);

        my ($initnm, $getternm, $setternm);
        my $namevalue = $self->get_attr_value($attrtext, "name");
        if ( $namevalue ) {
            $initnm = $namevalue;
            $getternm = $namevalue;
            $setternm = $namevalue;
        }
        else {
            $initnm = $self->get_attr_value($attrtext, "init_arg");
            $getternm = $self->get_attr_value($attrtext, "get");
            $setternm = $self->get_attr_value($attrtext, "set");
        }
        my $default = $self->get_attr_value($attrtext, "default");

        if ( $getternm ) {
            my $mtdnm = "get_".$getternm;
            my $mtd = $mdl->exist_method($mtdnm) ? $mdl->get_method($mtdnm)
                    :                              PlSense::Symbol::Method->new({ name => $mtdnm,
                                                                                  module => $mdl,
                                                                                  publicly => 1 });
            $mtd->set_importive(0);
            substkeeper->add_substitute($mtd->get_fullnm, $var->get_fullnm.".H:*", 1);
        }
        if ( $setternm ) {
            my $mtdnm = "set_".$setternm;
            my $mtd = $mdl->exist_method($mtdnm) ? $mdl->get_method($mtdnm)
                    :                              PlSense::Symbol::Method->new({ name => $mtdnm,
                                                                                  module => $mdl,
                                                                                  publicly => 1 });
            $mtd->set_importive(0);
            substkeeper->add_substitute($var->get_fullnm.".H:*", $mtd->get_fullnm."[2]", 1);
        }
        if ( $initnm ) {
            my $mtd = $mdl->get_method("new") or return;
            substkeeper->add_substitute($var->get_fullnm.".H:*", $mtd->get_fullnm."[2].R.H:".$initnm, 1);

            my @routes = addrrouter->get_route($mtd->get_fullnm."[2]");
            my $ref = first { eval { $_->isa("PlSense::Entity::Reference") } } @routes;
            if ( ! $ref ) {
                $ref = PlSense::Entity::Reference->new();
                substkeeper->add_substitute($mtd->get_fullnm."[2]", $ref, 1);
            }
            my $hash = $ref->get_entity;
            if ( ! eval { $hash->isa("PlSense::Entity::Hash") } ) {
                $hash = PlSense::Entity::Hash->new();
                $ref->set_entity($hash);
            }
            $hash->set_membernm($initnm);
            $hash->set_member(PlSense::Entity::Null->new());
        }
    }

    sub get_attr_value : PRIVATE {
        my ($self, $attrtext, $attrnm) = @_;
        if    ( $attrtext =~ m{ \b $attrnm => ' ([^']*) ' }xms     ) { return $1; }
        elsif ( $attrtext =~ m{ \b $attrnm => " ([^"]*) " }xms     ) { return $1; }
        elsif ( $attrtext =~ m{ : $attrnm < ([^>]+) > }xms         ) { return $1; }
        elsif ( $attrtext =~ m{ : $attrnm \( '? ([^']*) '? \) }xms ) { return $1; }
        elsif ( $attrtext =~ m{ : $attrnm \( "? ([^"]*) "? \) }xms ) { return $1; }
        return;
    }
}

1;

__END__
