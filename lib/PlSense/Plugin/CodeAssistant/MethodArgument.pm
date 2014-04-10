package PlSense::Plugin::CodeAssistant::MethodArgument;

use parent qw{ PlSense::Plugin::CodeAssistant };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
use PlSense::Util;
{
    sub is_valid_context {
        my ($self, $code, $tok) = @_;

        my $input = "";
        if ( $tok && $tok->isa("PPI::Token::Word") ) {
            $input = "".$tok->content."";
            $tok = $tok->parent or return;
            if ( ! $tok->isa("PPI::Statement") ) { return; }
            $tok = $tok->parent or return;
            if ( ! $tok->isa("PPI::Structure::Block") &&
                 ! $tok->isa("PPI::Structure::Constructor") &&
                 ! $tok->isa("PPI::Structure::List") ) {
                return;
            }
        }

        my $bracetok = $self->get_brace_token($tok) or return;
        my @tokens = $bracetok->children;
        my $rootstmt = pop @tokens or return;
        if ( ! $rootstmt->isa("PPI::Statement") ) { return; }

        $self->set_input($input);
        logger->info("Match context : input[$input]");

        @tokens = $self->get_valid_tokens($bracetok);
        my $rootaddr = addrfinder->find_address(@tokens);
        if ( ! $rootaddr ) {
            logger->info("Not found address in current context");
            return 1;
        }

        my $e = $bracetok->previous_sibling;
        $e = $e ? $e->previous_sibling : undef;
        my $objective = $e && $e->isa("PPI::Token::Operator") && $e->content eq '->' ? 1 : 0;

        @tokens = $rootstmt->children;
        my $idx = grep { $_->isa("PPI::Token::Operator") && $_->content eq ',' } @tokens;
        $idx = $objective ? $idx+2 : $idx+1;
        $rootaddr .= "[".$idx."]";

        my $addr = $self->get_current_address($rootaddr, $rootstmt);
        logger->notice("Found method argument of $addr");

        my $entity = addrrouter->resolve_address($addr);
        if ( ! $entity || ! $entity->isa("PlSense::Entity::Hash") ) {
            logger->notice("Not hash entity in current context");
            return 1;
        }

        MEMBER:
        foreach my $key ( $entity->keys_member ) {
            if ( $key eq '*' ) { next MEMBER; }
            $entity->set_membernm($key);
            my $value = $entity->get_member;
            $self->push_candidate($key, $value);
        }
        return 1;
    }

    sub get_brace_token : PRIVATE {
        my ($self, $tok) = @_;
        PARENT:
        while ( $tok ) {
            if ( $tok->isa("PPI::Structure::List") ) {
                my $pretok = $tok->previous_sibling or return;
                if ( $pretok->isa("PPI::Token::Word") ) {
                    return $tok;
                }
            }
            $tok = $tok->parent;
        }
        return;
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

    sub get_current_address : PRIVATE {
        my ($self, $addr, $rootstmt) = @_;
        my $nextstmt = $rootstmt;

        NEST:
        while ( $nextstmt && $nextstmt->isa("PPI::Statement") ) {

            $addr = $self->build_hash_member_address($addr, $nextstmt);
            my @tokens = $nextstmt->children;
            my $e = pop @tokens or last NEST;

            my $is_ref = 0;
            my $is_hash = 0;
            if ( $e->isa("PPI::Structure::Block") ) {
                $is_ref = 1;
                $is_hash = 1;
            }
            elsif ( $e->isa("PPI::Structure::List") ) {
            }
            elsif ( $e->isa("PPI::Structure::Constructor") ) {
                $is_ref = 1;
                my $value = "".$e->content."";
                if    ( $value =~ m{ \A \{ }xms ) { $is_hash = 1; }
                elsif ( $value =~ m{ \A \[ }xms ) {               }
                else                              { last NEST;    }
            }
            else {
                last NEST;
            }

            if ( $is_ref ) { $addr .= ".R"; }
            if ( $is_hash ) { $addr = $self->build_hash_member_address($addr, $e); }
            else            { $addr .= ".A"; }

            @tokens = $e->children;
            $nextstmt = pop @tokens;
        }

        return $addr;
    }

    sub build_hash_member_address : PRIVATE {
        my ($self, $addr, $tok) = @_;

        my $pretok = $tok->previous_sibling or return $addr;
        if ( $pretok->isa("PPI::Token::Whitespace") ) { $pretok = $pretok->previous_sibling; }
        if ( ! $pretok || $pretok->isa("PPI::Token::Operator") ) { return $addr; }
        $pretok = $pretok->previous_sibling or return $addr;
        if ( $pretok->isa("PPI::Token::Whitespace") ) { $pretok = $pretok->previous_sibling; }
        if ( ! $pretok || ! $pretok->isa("PPI::Token::Word") ) { return $addr; }

        return $addr.".H:".$pretok->content;
    }
}

1;

__END__
