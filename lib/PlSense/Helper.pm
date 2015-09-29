package PlSense::Helper;

use strict;
use warnings;
use Class::Std;
use PPI::Lexer;
use List::AllUtils qw{ first };
use PlSense::Logger;
use PlSense::Util;
{
    my %lexer_of :ATTR();

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;
        $lexer_of{$ident} = PPI::Lexer->new();
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
        my $mtd = $self->find_implicit_method($tok)
               || $self->find_explicit_method($tok)
               || $self->find_arrow_fmt_method($tok) or return "";
        logger->info("Found valid method : ".$mtd->get_fullnm);
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
        my $sym = $self->find_any_symbol($tok)
               || $self->find_implicit_method($tok)
               || $self->find_arrow_fmt_method($tok)
               || $self->find_module($tok) or return "";
        logger->info("Found valid symbol : ".$sym->get_fullnm);
        return $self->get_symbol_help_text($sym);
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
            my $entity = addrrouter->resolve_address($sym->get_fullnm);
            $ret .= $self->get_entity_description($entity);
            $ret .= $sym->get_helptext ? $sym->get_helptext."\n" : "\nNot documented.\n";
        }

        else {
            $ret = "Not documented.\n";
        }

        return $ret;
    }

    sub find_module : PRIVATE {
        my ($self, $tok) = @_;
        if ( ! $tok->isa("PPI::Token::Word") ) { return; }
        my $word = "".$tok->content."";
        return mdlkeeper->get_module($word);
    }

    sub find_implicit_method : PRIVATE {
        my ($self, $tok) = @_;
        if ( ! $tok->isa("PPI::Token::Word") ) { return; }
        my $word = "".$tok->content."";
        my $pretok = $tok->previous_sibling;
        if ( $pretok &&
             ! $pretok->isa("PPI::Token::Whitespace") &&
             ! ( $pretok->isa("PPI::Token::Operator") && $pretok->content eq ',' ) ) { return; }
        if ( $word =~ m{ \A ([a-zA-Z0-9:]+) :: ([a-zA-Z0-9_]+) \z }xms ) {
            my ($mdlnm, $mtdnm) = ($1, $2);
            my $mdl = mdlkeeper->get_module($mdlnm) or return;
            return $mdl->get_any_original_method($mtdnm);
        }
        else {
            my $mdl = addrfinder->get_currentmodule;
            return builtin->exist_method($word) ? builtin->get_method($word)
                 :                                $mdl->get_any_original_method($word);
        }
    }

    sub find_arrow_fmt_method : PRIVATE {
        my ($self, $tok) = @_;
        if ( ! $tok->isa("PPI::Token::Word") ) { return; }
        my $word = "".$tok->content."";
        my $pretok = $tok->previous_sibling or return;
        if ( ! $pretok->isa("PPI::Token::Operator") || $pretok->content ne '->' ) { return; }
        my @tokens = $self->get_valid_tokens($pretok);
        my $addr = addrfinder->find_address(@tokens);
        my $mdl;
        if ( $addr ) {
            my $entity = addrrouter->resolve_address($addr) or return;
            if ( ! $entity->isa("PlSense::Entity::Instance") ) { return; }
            $mdl = mdlkeeper->get_module($entity->get_modulenm) or return;
        }
        else {
            $pretok = pop @tokens or return;
            if ( ! $pretok->isa("PPI::Token::Word") ) { return; }
            $mdl = mdlkeeper->get_module("".$pretok->content."") or return;
        }
        return $mdl->get_any_original_method($word);
    }

    sub find_explicit_method : PRIVATE {
        my ($self, $tok) = @_;
        my $mtd = $self->find_any_symbol($tok) or return;
        if ( ! $mtd->isa("PlSense::Symbol::Method") ) { return; }
        return $mtd;
    }

    sub find_any_symbol : PRIVATE {
        my ($self, $tok) = @_;
        if ( ! $tok->isa("PPI::Token::Symbol") ) { return; }
        # Not use AddressFinder because can not detect the symbol type of incomplete code like $hoge[...
        my $symstr = "".$tok->content."";
        if ( $symstr !~ m{ \A (\$|@|%|&|\$\#) (.+ ::)? ([^:]+) \z }xms ) { return; }
        my ($symtype, $mdlnm, $symnm) = ($1, $2, $3);
        my ($mdl, $mtd);
        if ( ! $mdlnm ) {
            $mdl = addrfinder->get_currentmodule;
            $mtd = addrfinder->get_currentmethod;
        }
        else {
            $mdlnm =~ s{ :: \z }{}xms;
            $mdl = mdlkeeper->get_module($mdlnm) or return;
        }
        if ( $symtype eq '&' ) {
            if ( ! $mdl->exist_method($symnm) ) { return; }
            return $mdl->get_any_original_method($symnm);
        }
        else {
            my @varnms = $symtype eq '$'  ? ('$'.$symnm, '@'.$symnm, '%'.$symnm)
                       : $symtype eq '$#' ? ('@'.$symnm)
                       :                    ($symtype.$symnm);
            SEEK:
            foreach my $varnm ( @varnms ) {
                my $var = builtin->exist_variable($varnm)      ? builtin->get_variable($varnm)
                        : $mtd && $mtd->exist_variable($varnm) ? $mtd->get_variable($varnm)
                        : $mdl->exist_member($varnm)           ? $mdl->get_member($varnm)
                        :                                        first { $_->get_fullnm eq $varnm } $mdl->get_external_any_variables;
                if ( $var ) { return $var; }
            }
        }
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
            my $entity = addrrouter->resolve_address($var->get_fullnm);
            my $etext = ! $entity                                 ? "Unknown"
                      : $entity->isa("PlSense::Entity::Instance") ? $entity->get_modulenm
                      :                                             uc $entity->get_type;
            $idx++;
            $ret .= "ARG".$idx.": ".$var->get_name." As ".$etext."\n";
        }

        my @retaddrs = addrrouter->resolve_anything($mtd->get_fullnm);
        my $retaddr = $#retaddrs >= 0 ? $retaddrs[0] : "";
        my $retnm = eval { $retaddr->isa("PlSense::Entity") }                ? "Literal"
                  : $retaddr =~ m{ \A ([\$@%]) .+ :: ([a-zA-Z0-9_]+) \z }xms ? $1.$2
                  :                                                            "NoIdent";
        my $entity = addrrouter->resolve_address($mtd->get_fullnm);
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
            my $val = $entity->to_string;
            $val =~ s{ \A [A-Z]< \s* }{}xms;
            $val =~ s{ \s* > \z }{}xms;
            $ret .= ".\nThe value maybe ...\n".$val."\n";
        }
        else {
            $ret .= ".\n";
        }

        return $ret;
    }

}

1;

__END__
