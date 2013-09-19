package PlSense::Helper;

use strict;
use warnings;
use Class::Std;
use PPI::Lexer;
use List::AllUtils qw{ first };
use PlSense::Logger;
{
    my %addrrouter_of :ATTR( :init_arg<addrrouter> );
    my %addrfinder_of :ATTR( :init_arg<addrfinder> );
    my %lexer_of :ATTR();

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;
        $lexer_of{$ident} = PPI::Lexer->new();
    }

    sub get_currentmodule {
        my ($self) = @_;
        return $addrfinder_of{ident $self}->get_currentmodule;
    }

    sub get_currentmethod {
        my ($self) = @_;
        return $addrfinder_of{ident $self}->get_currentmethod;
    }

    sub get_any_help_text {
        my ($self, $any) = @_;
        if ( ! $any ) { return ""; }
        if ( eval { $any->isa("PlSense::Symbol") } ) {
            return $self->get_symbol_help_text($any);
        }
        elsif ( eval { $any->isa("PlSense::Entity") } ) {
            return $self->get_entity_description($any);
        }
        else {
            return "Not documented.\n";
        }
    }

    sub get_method_info_by_code {
        my ($self, $code) = @_;

        $code =~ s{ ^\s+ }{}xms;
        $code =~ s{ \s+$ }{}xms;
        if ( ! $code ) { return ""; }
        my $doc = $lexer_of{ident $self}->lex_source($code) or return "";
        $doc->prune("PPI::Token::Comment");
        $doc->prune("PPI::Token::Pod");
        # $doc->prune("PPI::Token::Whitespace");
        my $tok = eval { $doc->last_token } or return "";
        if ( ! $tok->isa("PPI::Token::Word") ) { return ""; }
        my $word = "".$tok->content."";
        my $pretok = $tok->previous_sibling;

        my $mtd;
        my $addrfinder = $addrfinder_of{ident $self};
        if ( ! $pretok || $pretok->isa("PPI::Token::Whitespace") ) {
            $mtd = $self->get_currentmodule->get_any_original_method($word);
            if ( ! $mtd && $addrfinder->get_builtin->exist_method($word) ) {
                $mtd = $addrfinder->get_builtin->get_method($word);
            }
        }
        elsif ( $pretok->isa("PPI::Token::Operator") && $pretok->content eq '->' ) {
            my @tokens = $self->get_valid_tokens($pretok);
            my $addr = $addrfinder->find_address(@tokens);
            my $mdl;
            if ( $addr ) {
                my $entity = $addrrouter_of{ident $self}->resolve_address($addr) or return "";
                if ( ! $entity->isa("PlSense::Entity::Instance") ) { return ""; }
                $mdl = $addrfinder->get_mdlkeeper->get_module($entity->get_modulenm) or return "";
            }
            else {
                $pretok = pop @tokens or return "";
                if ( ! $pretok->isa("PPI::Token::Word") ) { return ""; }
                $mdl = $addrfinder->get_mdlkeeper->get_module("".$pretok->content."") or return "";
            }
            if ( ! $mdl ) { return ""; }
            $mtd = $mdl->get_any_original_method($word) or return "";
        }
        if ( ! $mtd ) { return ""; }

        logger->info("Found valid method : ".$mtd->get_name);
        my $ret = "NAME: ".$mtd->get_name."\n";
        $ret .= $self->get_method_definition($mtd);
        $ret .= "FILE: ".($mtd->get_module ? $mtd->get_module->get_filepath : "")."\n";
        $ret .= "LINE: ".$mtd->get_linenumber."\n";
        $ret .= "COL: ".$mtd->get_colnumber."\n";
        return $ret;
    }

    sub get_help_text_by_code {
        my ($self, $code) = @_;

        $code =~ s{ ^\s+ }{}xms;
        $code =~ s{ \s+$ }{}xms;
        if ( ! $code ) { return ""; }
        my $doc = $lexer_of{ident $self}->lex_source($code) or return "";
        $doc->prune("PPI::Token::Comment");
        $doc->prune("PPI::Token::Pod");
        # $doc->prune("PPI::Token::Whitespace");
        my $tok = eval { $doc->last_token } or return "";

        my $addrfinder = $addrfinder_of{ident $self};
        if ( $tok->isa("PPI::Token::Word") ) {
            my $word = "".$tok->content."";
            my $pretok = $tok->previous_sibling;
            if ( $pretok && $pretok->isa("PPI::Token::Operator") && $pretok->content eq '->' ) {
                # Word is Instance/Static method
                my @tokens = $self->get_valid_tokens($pretok);
                my $addr = $addrfinder->find_address(@tokens);
                my $mdl;
                if ( $addr ) {
                    my $entity = $addrrouter_of{ident $self}->resolve_address($addr) or return "";
                    if ( ! $entity->isa("PlSense::Entity::Instance") ) { return ""; }
                    $mdl = $addrfinder->get_mdlkeeper->get_module($entity->get_modulenm) or return "";
                }
                else {
                    $pretok = pop @tokens or return "";
                    if ( ! $pretok->isa("PPI::Token::Word") ) { return ""; }
                    $mdl = $addrfinder->get_mdlkeeper->get_module("".$pretok->content."") or return "";
                }
                if ( ! $mdl ) { return ""; }
                my $mtd = $mdl->get_any_original_method($word) or return "";
                return $self->get_symbol_help_text($mtd);
            }
            elsif ( my $mdl = $addrfinder->get_mdlkeeper->get_module($word) ) {
                # Word is Module
                return $self->get_symbol_help_text($mdl);
            }
            elsif ( $addrfinder->get_builtin->exist_method($word) ) {
                # Word is Builtin method
                my $mtd = $addrfinder->get_builtin->get_method($word);
                return $self->get_symbol_help_text($mtd);
            }
            else {
                # Word is Other method
                my $addr = $addrfinder->find_address($tok) or return "";
                if ( $addr !~ m{ \A & (.+) :: ([^:]+) \z }xms ) { return ""; }
                my ($mdlkey, $mtdnm) = ($1, $2);
                my ($mdlnm, $filepath) = $mdlkey =~ m{ \A main \[ (.+) \] \z }xms ? ("main", $1)
                                       :                                            ($mdlkey, "");
                my $mdl = $addrfinder->get_mdlkeeper->get_module($mdlnm, $filepath) or return "";
                if ( ! $mdl->exist_method($mtdnm) ) { return ""; }
                my $mtd = $mdl->get_any_original_method($mtdnm);
                return $self->get_symbol_help_text($mtd);
            }
        }
        elsif ( $tok->isa("PPI::Token::Symbol") ) {
            # Word is Variable
            my $varnm = "".$tok->symbol."";
            my $mdl = $self->get_currentmodule;
            my $mtd = $self->get_currentmethod;
            my @varnms = $varnm =~ m{ ^\$ }xms ? ($varnm, '@'.substr($varnm, 1), '%'.substr($varnm, 1)) : ($varnm);
            my $var;
            SEEK:
            foreach my $varnm ( @varnms ) {
                $var = $addrfinder->get_builtin->exist_variable($varnm) ? $addrfinder->get_builtin->get_variable($varnm)
                     : $mtd && $mtd->exist_variable($varnm)             ? $mtd->get_variable($varnm)
                     : $mdl->exist_member($varnm)                       ? $mdl->get_member($varnm)
                     :                                                    first { $_->get_fullnm eq $varnm } $mdl->get_external_any_variables;
                if ( $var ) { last SEEK; }
            }
            if ( ! $var ) { return ""; }
            return $self->get_symbol_help_text($var);
        }
    }

    sub get_symbol_help_text {
        my ($self, $sym) = @_;
        my $ret = "";

        if ( ! $sym ) { return ""; }

        if ( $sym->isa("PlSense::Symbol::Module") ) {
            $ret = $sym->get_name." is Module.\n";
            $ret .= "defined in '".$sym->get_filepath."'.\n\n";
            $ret .= $sym->get_helptext ? $sym->get_helptext."\n" : "Not documented.\n";
        }

        elsif ( $sym->isa("PlSense::Symbol::Method") ) {
            my $mdl = $sym->get_module;
            if ( $mdl ) {
                $ret = $sym->get_name." is Method of ".$mdl->get_fullnm.".\n\n";
            }
            else {
                $ret = $sym->get_name." is Builtin Method.\n\n";
            }
            $ret .= $self->get_method_definition($sym);
            $ret .= $sym->get_helptext ? $sym->get_helptext."\n" : "\nNot documented.\n";
        }

        elsif ( $sym->isa("PlSense::Symbol::Variable") ) {
            my $owner = $sym->get_belong;
            if ( $owner ) {
                $ret = $sym->get_name." is Variable of ".$owner->get_fullnm.".\n\n";
            }
            else {
                $ret = $sym->get_name." is Builtin Variable.\n\n";
            }
            my $entity = $addrrouter_of{ident $self}->resolve_address($sym->get_fullnm);
            $ret .= $self->get_entity_description($entity);
            $ret .= $sym->get_helptext ? $sym->get_helptext."\n" : "\nNot documented.\n";
        }

        else {
            $ret = "Not documented.\n";
        }

        return $ret;
    }

    sub get_valid_tokens : PRIVATE {
        my ($self, $tok) = @_;
        my @ret;
        PRE_TOKEN:
        while ( $tok = $tok->previous_sibling ) {
            if ( $tok->isa("PPI::Token::Whitespace") ) { last PRE_TOKEN; }
            unshift @ret, $tok;
        }
        return @ret;
    }

    sub get_method_definition : PRIVATE {
        my ($self, $mtd) = @_;
        my $ret = "";

        my @mtdargs = $mtd->get_arguments;
        my $startidx = $mtd->get_module && $mtd->get_module->is_objective ? 1 : 0;
        my $idx = 0;
        ARG:
        for my $i ( $startidx..$#mtdargs ) {
            my $var = $mtdargs[$i];
            my $entity = $addrrouter_of{ident $self}->resolve_address($var->get_fullnm);
            my $etext = ! $entity                                 ? "Unknown"
                      : $entity->isa("PlSense::Entity::Instance") ? $entity->get_modulenm
                      :                                             uc $entity->get_type;
            $idx++;
            $ret .= "ARG".$idx.": ".$var->get_name." As ".$etext."\n";
        }

        my @retaddrs = $addrrouter_of{ident $self}->resolve_anything($mtd->get_fullnm);
        my $retaddr = $#retaddrs >= 0 ? $retaddrs[0] : "";
        my $retnm = eval { $retaddr->isa("PlSense::Entity") }                ? "Literal"
                  : $retaddr =~ m{ \A ([\$@%]) .+ :: ([a-zA-Z0-9_]+) \z }xms ? $1.$2
                  :                                                            "NoIdent";
        my $entity = $addrrouter_of{ident $self}->resolve_address($mtd->get_fullnm);
        my $etext = ! $entity                                 ? "Unknown"
                  : $entity->isa("PlSense::Entity::Instance") ? $entity->get_modulenm
                  :                                             uc $entity->get_type;
        $ret .= "RETURN: $retnm As $etext\n";

        return $ret;
    }

    sub get_entity_description : PRIVATE {
        my ($self, $entity) = @_;

        my $etype = eval { $entity->get_type } || "Unknown";

        my $ret = "This is ".uc($etype);
        if ( $etype eq 'instance' ) {
            my $mdlnm = $entity->get_modulenm || "Unknown";
            $ret .= " of $mdlnm.\n";
        }
        elsif ( $etype ne 'Unknown' ) {
            $ret .= ".\nThe value maybe ...\n".$entity->to_string."\n";
        }
        else {
            $ret .= ".\n";
        }

        return $ret;
    }

}

1;

__END__
