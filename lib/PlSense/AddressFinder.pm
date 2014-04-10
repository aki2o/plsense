package PlSense::AddressFinder;

use strict;
use warnings;
use Class::Std;
use PPI::Lexer;
use Module::Pluggable instantiate => 'new', search_path => [ 'PlSense::Plugin::AddressFinder::Builtin',
                                                             'PlSense::Plugin::AddressFinder::Ext' ];
use PlSense::Logger;
use PlSense::Util;
use PlSense::Entity::Null;
use PlSense::Entity::Scalar;
use PlSense::Entity::Array;
use PlSense::Entity::Hash;
use PlSense::Entity::Reference;
{
    my %bpluginh_of :ATTR();
    my %epluginh_of :ATTR();
    my %lexer_of :ATTR();

    my %with_build_is :ATTR( :init_arg<with_build> );
    sub with_build { my ($self) = @_; return $with_build_is{ident $self} ? 1 : 0; }

    my %methodindex_of :ATTR( :default(0) );
    sub get_methodindex { my ($self) = @_; return $methodindex_of{ident $self}; }
    sub forward_methodindex { my ($self) = @_; $methodindex_of{ident $self}++; }

    my %currentmodule_of :ATTR( :default(undef) );
    sub set_currentmodule {
        my ($self, $currentmodule) = @_;
        if ( ! $currentmodule || ! $currentmodule->isa("PlSense::Symbol::Module") ) {
            logger->error("Not PlSense::Symbol::Module");
            return;
        }
        $currentmodule_of{ident $self} = $currentmodule;
        $self->init_currentmethod;
    }
    sub get_currentmodule { my ($self) = @_; return $currentmodule_of{ident $self}; }

    my %currentmethod_of :ATTR( :default(undef) );
    sub set_currentmethod {
        my ($self, $currentmethod) = @_;
        if ( ! $currentmethod || ! $currentmethod->isa("PlSense::Symbol::Method") ) {
            logger->error("Not PlSense::Symbol::Method");
            return;
        }
        $currentmethod_of{ident $self} = $currentmethod;
        $methodindex_of{ident $self} = 0;
    }
    sub get_currentmethod { my ($self) = @_; return $currentmethod_of{ident $self}; }
    sub init_currentmethod { my ($self) = @_; undef $currentmethod_of{ident $self}; }

    sub BUILD {
        my ($class, $ident, $arg_ref) = @_;
        $bpluginh_of{$ident} = {};
        $epluginh_of{$ident} = {};
        $lexer_of{$ident} = PPI::Lexer->new();
    }

    sub START {
        my ($class, $ident, $arg_ref) = @_;
        my @plugins = $class->plugins({ mediator => $class,
                                        with_build => $class->with_build });
        PLUGIN:
        foreach my $p ( grep { $_->isa("PlSense::Plugin::AddressFinder::Builtin") } @plugins ) {
            $bpluginh_of{$ident}->{$p->get_builtin_name} = $p;
        }
        PLUGIN:
        foreach my $p ( grep { $_->isa("PlSense::Plugin::AddressFinder::Ext") } @plugins ) {
            $epluginh_of{$ident}->{$p->get_method_name} = $p;
        }
    }

    sub find_address {
        my ($self, @tokens) = @_;
        @tokens = $self->get_valid_tokens(@tokens);
        return $self->find_address_in_cast(@tokens)
            || $self->find_address_in_symbol(@tokens)
            || $self->find_address_in_magic(@tokens)
            || $self->find_something_in_word(1, @tokens);
    }

    sub find_address_or_entity {
        my ($self, @tokens) = @_;
        @tokens = $self->get_valid_tokens(@tokens);
        return $self->find_in_binomial_operator(0, @tokens)
            || $self->find_in_ternary_operator(0, @tokens)
            || $self->find_entity_in_literal(@tokens)
            || $self->find_array_in_list(@tokens)
            || $self->find_something_in_word(0, @tokens)
            || $self->find_entity_in_cast(@tokens)
            || $self->find_address(@tokens);
    }

    sub find_addresses {
        my ($self, @tokens) = @_;
        my @ret;
        @tokens = $self->get_valid_tokens(@tokens);
        @ret = $self->find_somethings_in_list(1, @tokens);
        if ( $#ret >= 0 ) { return @ret; }
        my $ret = $self->find_address(@tokens);
        if ( $ret ) { return ($ret); }
        return ();
    }

    sub find_addresses_or_entities {
        my ($self, @tokens) = @_;
        my @ret;
        @tokens = $self->get_valid_tokens(@tokens);
        @ret = $self->find_in_binomial_operator(1, @tokens);
        if ( $#ret >= 0 ) { return @ret; }
        @ret = $self->find_in_ternary_operator(1, @tokens);
        if ( $#ret >= 0 ) { return @ret; }
        @ret = $self->find_somethings_in_list(0, @tokens);
        if ( $#ret >= 0 ) { return @ret; }
        my $ret = $self->find_address_or_entity(@tokens);
        if ( $ret ) { return ($ret); }
        return ();
    }


    sub get_valid_tokens : PRIVATE {
        my ($self, @tokens) = @_;
        my @ret = ();
        ELEMENT:
        foreach my $e ( @tokens ) {
            if ( $e->isa("PPI::Token::Structure") && $e->content eq ";" ) { last ELEMENT; }
            if ( $e->isa("PPI::Token::Operator") && $e->content eq "and" ) { last ELEMENT; }
            if ( $e->isa("PPI::Token::Operator") && $e->content eq "or" ) { last ELEMENT; }
            push @ret, $e;
        }
        return @ret;
    }

    sub find_in_binomial_operator : PRIVATE {
        my ($self, $is_list, @tokens) = @_;
        my $lastidx = 0;
        TOKEN:
        for my $i ( 0..$#tokens ) {
            my $e = $tokens[$i];
            if ( ! $e->isa("PPI::Token::Operator") ) { next TOKEN; }
            if ( $e->content eq "&&" ) {
                $lastidx = $i + 1;
            }
            elsif ( $e->content eq "||" ) {
                logger->info("Found binomial operator : ".join(" ", @tokens[$lastidx..($i-1)]));
                if ( $i > $lastidx ) {
                    if ( $is_list ) {
                        return $self->find_addresses_or_entities(@tokens[$lastidx..($i-1)]);
                    }
                    else {
                        return $self->find_address_or_entity(@tokens[$lastidx..($i-1)]);
                    }
                }
            }
        }
        if ( $lastidx > 0 && $lastidx < $#tokens ) {
            logger->info("Found binomial operator : ".join(" ", @tokens[$lastidx..$#tokens]));
            if ( $is_list ) {
                return $self->find_addresses_or_entities(@tokens[$lastidx..$#tokens]);
            }
            else {
                return $self->find_address_or_entity(@tokens[$lastidx..$#tokens]);
            }
        }
        return;
    }

    sub find_in_ternary_operator : PRIVATE {
        my ($self, $is_list, @tokens) = @_;
        my $lastidx = 0;
        ELEMENT:
        for my $i ( 0..$#tokens ) {
            my $e = $tokens[$i];
            if ( $e->isa("PPI::Token::Operator") && $e->content eq "?" ) {
                $lastidx = $i + 1;
            }
            elsif ( $lastidx > 0 && $i > $lastidx && $e->isa("PPI::Token::Operator") && $e->content eq ":" ) {
                logger->info("Found ternary operator : ".join(" ", @tokens[$lastidx..($i-1)]));
                if ( $is_list ) {
                    return $self->find_addresses_or_entities(@tokens[$lastidx..($i-1)]);
                }
                else {
                    return $self->find_address_or_entity(@tokens[$lastidx..($i-1)]);
                }
            }
            elsif ( $lastidx > 0 && $i >= $lastidx && $e->isa("PPI::Token::Label") ) {
                my $currvalue = "".$e->content."";
                $currvalue =~ s{ \s* : \z }{}xms;
                logger->info("Found ternary operator : ".join(" ", @tokens[$lastidx..($i-1)])." $currvalue");
                my $doc = $lexer_of{ident $self}->lex_source( $currvalue );
                if ( ! $doc ) { return; }
                my $tok = $doc->last_token;
                my @currtokens = $i > $lastidx ? @tokens[$lastidx..($i-1)] : ();
                push @currtokens, $tok;
                if ( $is_list ) {
                    return $self->find_addresses_or_entities(@currtokens);
                }
                else {
                    return $self->find_address_or_entity(@currtokens);
                }
            }
        }
        return;
    }

    sub find_array_in_list : PRIVATE {
        my ($self, @tokens) = @_;
        my @ret = $self->find_somethings_in_list(0, @tokens);
        if ( $#ret < 0 ) { return; }
        my $entity = PlSense::Entity::Array->new();
        FOUND:
        foreach my $any ( @ret ) {
            if ( eval { $any->isa("PlSense::Entity") } ) {
                $entity->set_element($any);
            }
            else {
                $entity->push_address($any);
            }
        }
        return $entity;
    }

    sub find_somethings_in_list : PRIVATE {
        my ($self, $is_addr, @tokens) = @_;
        my (@ret, @parts);
        my $e = shift @tokens or return @ret;
        if ( ! $e->isa("PPI::Structure::List") ) { return @ret; }

        my $lite = $self->find_entity_in_literal($e, @tokens);
        if ( $lite ) { return $is_addr ? () : ($lite); }

        logger->info("Found list : ".$e->content);
        my @children = $e->children;
        if ( $#children < 0 ) { return @ret; }
        $e = shift @children or return @ret;
        if ( ! $e->isa("PPI::Statement") ) { return @ret; }
        @children = $e->children;
        SHIFT_CHILD:
        while ( my $c = shift @children ) {
            if ( $c->isa("PPI::Token::Operator") && $c->content eq "," ) {
                push @ret, $is_addr ? $self->find_address(@parts) : $self->find_address_or_entity(@parts);
                @parts = ();
            }
            else {
                push @parts, $c;
            }
        }
        if ( $#parts >= 0 ) {
            push @ret, $is_addr ? $self->find_address(@parts) : $self->find_address_or_entity(@parts);
        }
        return @ret;
    }

    sub find_entity_in_literal : PRIVATE {
        my ($self, @tokens) = @_;
        my $e = shift @tokens or return;
        if ( $e->isa("PPI::Token::Number") ) {
            my $value = "".$e->content."";
            logger->info("Found literal number : ".$value);
            return PlSense::Entity::Scalar->new({ value => $value });
        }
        elsif ( $e->isa("PPI::Token::Quote") ) {
            my $value;
            if ( $e->isa("PPI::Token::Quote::Single") ) {
                $value = "".$e->literal."";
            }
            else {
                $value = "".$e->content."";
                $value =~ s{ \A ("|') }{}xms;
                $value =~ s{ ("|') \z }{}xms;
            }
            logger->info("Found literal quote : ".$value);
            return PlSense::Entity::Scalar->new({ value => $value });
        }
        elsif ( $e->isa("PPI::Token::QuoteLike::Words") ) {
            my @values = $e->literal;
            my $value = join(" ", @values);
            logger->info("Found literal quotelike words : ".$value);
            my $entity = PlSense::Entity::Scalar->new({ value => $value });
            return PlSense::Entity::Array->new({ element => $entity });
        }
        elsif ( $e->isa("PPI::Token::QuoteLike") ) {
            my $value = "".$e->content."";
            logger->info("Found literal quotelike : ".$value);
            return PlSense::Entity::Scalar->new({ value => $value });
        }
        elsif ( $e->isa("PPI::Token::HereDoc") ) {
            my $value = "".$e->content."";
            logger->info("Found literal heredoc : ".$value);
            return PlSense::Entity::Scalar->new({ value => $value });
        }
        elsif ( $e->isa("PPI::Token::ArrayIndex") ) {
            my $value = "".$e->content."";
            logger->info("Found literal arrayindex : ".$value);
            return PlSense::Entity::Scalar->new({ value => $value });
        }
        elsif ( $e->isa("PPI::Structure::List") ) {
            my @children = $e->children;
            $e = shift @children or return;
            if ( ! $e->isa("PPI::Statement::Expression") ) { return; }
            my $constructor = $self->get_hash_constructor($e->children) or return;
            logger->info("Found literal hash constructor : ".$e->content);
            my $entity = PlSense::Entity::Hash->new();
            KEY:
            foreach my $key ( keys %$constructor ) {
                my $value = $constructor->{$key};
                $entity->set_membernm($key);
                $entity->set_member( $value ? $value : PlSense::Entity::Null->new() );
            }
            return $entity;
        }
        elsif ( $e->isa("PPI::Structure::Constructor") ) {
            my $value = "".$e->content."";
            if ( $value =~ m{ \A \{ }xms ) {
                logger->info("Found literal hash ref constructor : ".$value);
                my $entity = PlSense::Entity::Hash->new();
                my @children = $e->children;
                $e = shift @children;
                if ( $e && $e->isa("PPI::Statement::Expression") ) {
                    my $constructor = $self->get_hash_constructor($e->children);
                    if ( $constructor ) {
                        KEY:
                        foreach my $key ( keys %$constructor ) {
                            my $value = $constructor->{$key};
                            $entity->set_membernm($key);
                            $entity->set_member( $value ? $value : PlSense::Entity::Null->new() );
                        }
                    }
                }
                return PlSense::Entity::Reference->new({ entity => $entity });
            }
            elsif ( $value =~ m{ \A \[ }xms ) {
                logger->info("Found literal array ref constructor : ".$value);
                my $entity = PlSense::Entity::Array->new({ element => PlSense::Entity::Null->new() });
                return PlSense::Entity::Reference->new({ entity => $entity });
            }
        }
        return;
    }

    sub get_hash_constructor : PRIVATE {
        my ($self, @tokens) = @_;
        my @parts;
        my $key = "";
        my $pre;
        my %ret;
        TOKEN:
        while ( my $e = shift @tokens ) {
            if ( $e->isa("PPI::Token::Operator") && $e->content eq "," ) {
                if ( ! $key ) { return; }
                $ret{$key} = $self->find_address_or_entity(@parts);
                $key = "";
            }
            elsif ( $e->isa("PPI::Token::Operator") && $e->content eq '=>' ) {
                if ( $pre->isa("PPI::Token::Word") ) {
                    $key = "".$pre->literal."";
                }
                @parts = ();
            }
            else {
                push @parts, $e;
            }
            $pre = $e;
        }
        if ( $key && $#parts >= 0 ) {
            $ret{$key} = $self->find_address_or_entity(@parts);
        }
        my @keys = keys %ret;
        return $#keys >= 0 ? \%ret : undef;
    }

    sub find_address_in_cast : PRIVATE {
        my ($self, @tokens) = @_;
        my $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Token::Cast") || $e->content eq "\\" ) { return; }
        my $next = shift @tokens;
        my @casted;
        if ( $next->isa("PPI::Structure::Block") ) {
            my $stmt = $next->find_first("PPI::Statement");
            @casted = $stmt->children();
        }
        else {
            @casted = ($next);
        }
        my $addr = $self->find_address_in_symbol(@casted) or return;
        logger->info("Found cast : ".$addr);
        return $self->build_address_anything("$addr.R", @tokens);
    }

    sub find_entity_in_cast : PRIVATE {
        my ($self, @tokens) = @_;
        my $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Token::Cast") || $e->content ne "\\" ) { return; }
        my $next = shift @tokens;
        my @casted;
        if ( $next->isa("PPI::Structure::Block") ) {
            my $stmt = $next->find_first("PPI::Statement");
            @casted = $stmt->children();
        }
        else {
            @casted = ($next);
        }
        my $addr = $self->find_address_in_symbol(@casted) or return;
        logger->info("Found cast : ".$addr);
        return PlSense::Entity::Reference->new({ entity => $addr });
    }

    sub find_address_in_magic : PRIVATE {
        my ($self, @tokens) = @_;
        my $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Token::Magic") || $e->content ne '@_' ) { return; };
        my $mtd = $self->get_currentmethod or return;
        return '@'.$mtd->get_fullnm."::_";
    }

    sub find_address_in_symbol : PRIVATE {
        my ($self, @tokens) = @_;
        my $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Token::Symbol") ) { return; }
        my $varnm = $e->symbol || "";
        my $mdl = $self->get_currentmodule;
        my $mtd = $self->get_currentmethod;

        if ( builtin->exist_variable($varnm) ) {
            logger->debug("Found builtin variable : $varnm");
            my $p = $bpluginh_of{ident $self}->{$varnm};
            if ( $p ) { return $p->find_address(@tokens); }
            return;
        }

        if ( $mtd && $mtd->exist_variable($varnm) ) {
            logger->info("Found method local variable : ".$varnm);
            my $var = $mtd->get_variable($varnm);
            return $self->build_address_anything($var->get_fullnm, @tokens);
        }

        if ( $mdl->exist_member($varnm) ) {
            logger->info("Found own variable : ".$varnm);
            my $var = $mdl->get_member($varnm);
            return $self->build_address_anything($var->get_fullnm, @tokens);
        }

        if ( $varnm =~ m{ \A (\$|@|%|&) ([a-zA-Z0-9:]+) :: ([a-zA-Z0-9_]+) \z }xms ) {
            my ($type, $mdlnm, $somenm) = ($1, $2, $3);
            my $m = mdlkeeper->get_module($mdlnm) or return;
            my $addr = $type.$mdlnm."::".$somenm;
            if ( $type eq '&' ) {
                logger->info("Found used method : ".$addr);
                return $self->build_address_anything_with_method_arg($addr, @tokens);
            }
            else {
                logger->info("Found used variable : ".$addr);
                return $self->build_address_anything($addr, @tokens);
            }
        }

        logger->debug($mtd ? "Unknown symbol[$varnm] in module[".$mdl->get_name."] method[".$mtd->get_name."]"
                      :      "Unknown symbol[$varnm] in module[".$mdl->get_name."]");
        return;
    }

    sub find_something_in_word : PRIVATE {
        my ($self, $is_addr, @tokens) = @_;
        my $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Token::Word") ) { return; }
        my $currwd = "".$e->literal."";
        my $mdl = $self->get_currentmodule;

        if ( $mdl->exist_method($currwd) ) {
            my $pret;
            my $p = $epluginh_of{ident $self}->{$currwd};
            if ( $p ) {
                logger->info("Found importive method : $currwd");
                $pret = $is_addr ? $p->find_address( $p->get_argument_tokens(@tokens) )
                      :            $p->find_address_or_entity( $p->get_argument_tokens(@tokens) );
            }
            if ( $pret ) { return $pret; }
            logger->info("Found own method : $currwd");
            my $mtd = $mdl->get_method($currwd);
            return $self->build_address_anything_with_method_arg($mtd->get_fullnm, @tokens);
        }

        if ( builtin->exist_method($currwd) ) {
            logger->debug("Found builtin function : $currwd");
            my $p = $bpluginh_of{ident $self}->{$currwd};
            if ( $p ) {
                return $is_addr ? $p->find_address( $p->get_argument_tokens(@tokens) )
                     :            $p->find_address_or_entity( $p->get_argument_tokens(@tokens) );
            }
            return;
        }

        my $m = mdlkeeper->get_module($currwd);
        if ( $m ) {
            logger->info("Found module : $currwd");
            return $self->build_address_literal_method($m, @tokens);
        }

        if ( $currwd =~ m{ \A ([a-zA-Z0-9:]+) :: ([a-zA-Z0-9_]+) \z }xms ) {
            my ($mdlnm, $mtdnm) = ($1, $2);
            my $m = mdlkeeper->get_module($mdlnm) or return;
            my $addr = $mdlnm."::".$mtdnm;
            logger->info("Found used method : $addr");
            return $self->build_address_anything_with_method_arg("&".$addr, @tokens);
        }

        logger->debug("Unknown word[".$currwd."] in module[".$mdl->get_name."]");
        return;
    }

    sub build_address_literal_method : PRIVATE {
        my ($self, $mdl, @tokens) = @_;
        if ( ! $mdl || ! $mdl->isa("PlSense::Symbol::Module") ) {
            logger->error("Not PlSense::Symbol::Module");
            return;
        }
        my $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Token::Operator") || $e->content ne '->' ) { return; }
        $e = shift @tokens;
        if ( ! $e || ! $e->isa("PPI::Token::Word") ) { return; }
        my $addr = "&".$mdl->get_fullnm."::".$e->content;
        logger->info("Found called literal method : ".$e->content);
        return $self->build_address_anything_with_method_arg($addr, @tokens);
    }

    sub build_address_anything_with_method_arg : PRIVATE {
        my ($self, $addr, @tokens) = @_;
        return $self->with_build ? $self->build_address_anything_with_build_method_arg($addr, @tokens)
             :                     $self->build_address_anything_with_skip_method_arg($addr, @tokens);
    }

    sub build_address_anything_with_build_method_arg : PRIVATE {
        my ($self, $addr, @tokens) = @_;
        my @values = $self->find_addresses_or_entities(@tokens);
        if ( $#values >= 0 ) {
            my $e = shift @tokens;
            $e = $e ? $e->previous_sibling : undef;
            $e = $e ? $e->previous_sibling : undef;
            my $objective = $e && $e->isa("PPI::Token::Operator") && $e->content eq '->' ? 1 : 0;
            my $resolved_addr = $addr =~ m{ \A .+ \.W: [^.]+ \z }xms ? 0 : 1;
            ARGUMENT:
            for my $i ( 0..$#values ) {
                my $idx = $objective ? $i+2 : $i+1;
                if ( $resolved_addr ) {
                    substkeeper->add_substitute($addr."[".$idx."]", $values[$i]);
                }
                else {
                    substkeeper->add_unknown_argument($addr, $idx, $values[$i]);
                }
            }
        }
        return $self->build_address_anything($addr, @tokens);
    }

    sub build_address_anything_with_skip_method_arg : PRIVATE {
        my ($self, $addr, @tokens) = @_;
        my $e = shift @tokens;
        return $e && $e->isa("PPI::Structure::List") ? $self->build_address_anything($addr, @tokens)
             :                                         $self->build_address_anything($addr, $e, @tokens);
    }

    sub build_address_anything : PRIVATE {
        my ($self, $addr, @tokens) = @_;
        return $self->build_address_word($addr, @tokens)
            || $self->build_address_subscript($addr, @tokens)
            || $self->build_address_referencing_subscript($addr, @tokens)
            || $addr;
    }

    sub build_address_word : PRIVATE {
        my ($self, $addr, @tokens) = @_;
        my $ope = shift @tokens or return;
        if ( ! $ope->isa("PPI::Token::Operator") || $ope->content ne '->' ) { return; }
        my $word = shift @tokens or return;
        if ( ! $word->isa("PPI::Token::Word") ) { return; }
        $addr = $addr.".W:".$word->content;
        return $self->build_address_anything_with_method_arg($addr, @tokens);
    }

    sub build_address_subscript : PRIVATE {
        my ($self, $addr, @tokens) = @_;
        my $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Structure::Subscript") ) { return; }
        my $brace_s = $e->start;
        if ( $brace_s eq '{' ) {
            my $membernm = "".$e->content."";
            $membernm =~ s{ \A (\{|\[) \s* }{}xms;
            $membernm =~ s{ \s* (\}|\]) \z }{}xms;
            $membernm =~ s{ \A ("|') }{}xms;
            $membernm =~ s{ ("|') \z }{}xms;
            if ( $membernm !~ m{ \A [a-zA-Z0-9_\-]+ \z }xms ) { $membernm = '*'; }
            return $self->build_address_anything("$addr.H:$membernm", @tokens);
        }
        elsif ( $brace_s eq '[' ) {
            return $self->build_address_anything("$addr.A", @tokens);
        }
        logger->debug("Unknown brace : ".$brace_s);
        return;
    }

    sub build_address_referencing_subscript : PRIVATE {
        my ($self, $addr, @tokens) = @_;
        my $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Token::Operator") || $e->content ne '->' ) { return; }
        $e = shift @tokens or return;
        if ( ! $e->isa("PPI::Structure::Subscript") ) { return; }
        return $self->build_address_subscript("$addr.R", $e, @tokens);
    }
}

1;

__END__
