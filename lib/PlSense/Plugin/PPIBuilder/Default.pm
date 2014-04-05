package PlSense::Plugin::PPIBuilder::Default;

use parent qw{ PlSense::Plugin::PPIBuilder };
use strict;
use warnings;
use Class::Std;
use List::AllUtils qw{ firstidx };
use PlSense::Logger;
use PlSense::Util;
use PlSense::Entity::Instance;
use PlSense::Entity::Hash;
use PlSense::Symbol::Variable;
{
    sub end {
        my ($self, $mdl, $ppi) = @_;
        if ( $mdl->get_name eq 'main' || ! $mdl->is_objective ) { return; }

        my $mtd = $mdl->get_method("new") or return;
        my $entity = PlSense::Entity::Instance->new({ modulenm => $mdl->get_name, });
        substkeeper->add_substitute($mtd->get_fullnm, $entity, 1);
        my $baddr = '&'.$mdl->get_name.'::BLESS';
        substkeeper->add_substitute($baddr, $entity, 1);

        PARENT:
        for my $i ( 1..$mdl->count_parent ) {
            my $parent = $mdl->get_parent($i);
            substkeeper->add_substitute("&".$mdl->get_fullnm."::new[2]", "&".$parent->get_fullnm."::new[2]", 1);
        }
    }

    sub scheduled_statement {
        my ($self, $mdl, $scheduled_type, $stmt) = @_;
        if ( $scheduled_type eq "END" ) { return; }
        if ( $stmt->isa("PPI::Statement::Break") ) { return; }
        if ( $stmt->isa("PPI::Statement::Compound") ) { return; }
        my @tokens = $stmt->children;
        $self->build_by_variable_substituted($stmt, @tokens)
        || $self->build_by_normal_statement($stmt, @tokens);
    }

    sub sub_statement {
        my ($self, $mtd, $stmt) = @_;
        my $mdl = $mtd->get_module or return;
        if ( $mdl->is_objective ) {
            my $baddr = '&'.$mdl->get_name.'::BLESS';
            substkeeper->add_substitute($mtd->get_fullnm."[1]", $baddr, 1);
        }

        my $block = $stmt->block or return;
        my @statements = $block->children;
        my $laststmt = pop @statements or return;
        if ( $laststmt->isa("PPI::Statement::Break") ) {
            $self->build_by_break_statement($mtd, $laststmt);
        }
        elsif ( $laststmt->isa("PPI::Statement") ) {
            my @tokens = $laststmt->children;
            logger->info("Found method last statement : ".$laststmt->content);
            substbuilder->build_method_return($mtd, @tokens);
        }
    }

    sub variable_statement {
        my ($self, $vars, $stmt) = @_;
        my @tokens = $stmt->children;
        my $eqidx = firstidx { $_->isa("PPI::Token::Operator") && $_->content eq "=" } @tokens;
        if ( $eqidx < 0 || $eqidx >= $#tokens ) { return; }
        $eqidx++;
        substbuilder->build_variable_substitute( $vars, @tokens[$eqidx..$#tokens] );
    }

    sub other_statement {
        my ($self, $mdl, $mtd, $stmt) = @_;
        if ( $stmt->isa("PPI::Statement::Break") && $mtd ) {
            $self->build_by_break_statement($mtd, $stmt);
        }
        elsif ( $stmt->isa("PPI::Statement::Compound") ) {
            my @tokens = $stmt->children;
            my $e = shift @tokens or return;
            if ( $e->isa("PPI::Token::Label") ) { $e = shift @tokens or return; }
            if ( ! $e->isa("PPI::Token::Word") ) { return; }
            if    ( $e->content eq "for" )     { $self->build_by_for_statement($mdl, $mtd, @tokens); }
            elsif ( $e->content eq "foreach" ) { $self->build_by_foreach_statement($mdl, $mtd, @tokens); }
            elsif ( $e->content eq "while" )   { $self->build_by_while_statement($mdl, $mtd, @tokens); }
        }
        else {
            my @tokens = $stmt->children;
            $self->build_by_variable_substituted($stmt, @tokens)
            || $self->build_by_normal_statement($stmt, @tokens);
        }
    }


    sub build_by_variable_substituted : PRIVATE {
        my ($self, $stmt, @tokens) = @_;
        my $eqidx = firstidx { $_->isa("PPI::Token::Operator") && $_->content eq "=" } @tokens;
        if ( $eqidx <= 0 || $eqidx >= $#tokens ) { return; }
        logger->info("Found substitute statement : ".$stmt->content);
        my @lefts = @tokens[0..($eqidx-1)];
        my @rights = @tokens[($eqidx+1)..$#tokens];
        substbuilder->build_substitute_with_find_variable( \@lefts, @rights );
        return 1;
    }

    sub build_by_normal_statement : PRIVATE {
        my ($self, $stmt, @tokens) = @_;
        substbuilder->build_any_substitute_from_normal_statement(@tokens);
    }

    sub build_by_break_statement : PRIVATE {
        my ($self, $mtd, $stmt) = @_;
        my @tokens = $stmt->children;
        my $e = shift @tokens or return;
        if ( $e->content ne "return" ) { return; }
        logger->info("Found method break statement : ".$stmt->content);
        substbuilder->build_method_return($mtd, @tokens);
    }

    sub build_by_for_statement : PRIVATE {
        my ($self, $mdl, $mtd, @tokens) = @_;
        $self->build_by_foreach_statement($mdl, $mtd, @tokens);
    }

    sub build_by_foreach_statement : PRIVATE {
        my ($self, $mdl, $mtd, @tokens) = @_;

        my $lexical;
        my $e = shift @tokens or return;
        if ( $e->isa("PPI::Token::Word") && $e->content eq "my" ) {
            $lexical = 1;
            $e = shift @tokens or return;
        }
        if ( ! $e->isa("PPI::Token::Symbol") ) { return; }

        my $varnm = "".$e->content."";
        my $var = $mtd && $mtd->exist_variable($varnm) ? $mtd->get_variable($varnm)
                : $mdl->exist_member($varnm)           ? $mdl->get_member($varnm)
                : $lexical                             ? PlSense::Symbol::Variable->new({ name => "$varnm",
                                                                                          lexical => 1,
                                                                                          belong => $mtd ? $mtd : $mdl, })
                :                                        undef;
        if ( ! $var ) { return; }

        $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Structure::List") ) { return; }
        my @children = $e->children;
        if ( $#children < 0 ) { return; }
        $e = shift @children or return;
        if ( ! $e->isa("PPI::Statement") ) { return; }
        logger->info("Found for/foreach statement : ".$e->content);
        @children = $e->children;

        my $any = addrfinder->find_address_or_entity(@children) or return;
        if ( eval { $any->isa("PlSense::Entity") } ) {
            if ( ! $any->isa("PlSense::Entity::Array") ) { return; }
            my $el = $any->get_element;
            if ( $el ) {
                substkeeper->add_substitute($var->get_fullnm, $el);
            }
            elsif ( $any->count_address > 0 ) {
                substkeeper->add_substitute($var->get_fullnm, $any->get_address(1).".A");
            }
        }
        else {
            substkeeper->add_substitute($var->get_fullnm, $any.".A");
        }
    }

    sub build_by_while_statement : PRIVATE {
        my ($self, $mdl, $mtd, @tokens) = @_;

        my $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Structure::Condition") ) { return; }

        my @children = $e->children;
        my $eqidx = firstidx { $_->isa("PPI::Token::Operator") && $_->content eq "=" } @children;
        if ( $eqidx <= 0 || $eqidx >= $#children ) { return; }

        logger->info("Found while statement : ".$e->content);
        my @lefts = @children[0..($eqidx-1)];
        my @rights = @children[($eqidx+1)..$#children];
    }
}

1;

__END__
