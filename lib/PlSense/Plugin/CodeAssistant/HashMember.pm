package PlSense::Plugin::CodeAssistant::HashMember;

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
        my $is_ref = 0;
        if ( $code =~ m{ -> \{ \s* ["']? ([a-zA-Z0-9_\-]*) \z }xms ) {
            $input = $1;
            $is_ref = 1;
        }
        elsif ( $code =~ m{ \{ \s* ["']? ([a-zA-Z0-9_\-]*) \z }xms ) {
            $input = $1;
        }
        else {
            return;
        }

        my $stmt;
        if ( ! $input ) {
            $tok = $tok->parent or return;
            $stmt = $tok->parent or return;
        }
        else {
            if ( ! $tok ) { return; }
            $tok = $tok->parent or return;
            $tok = $tok->parent or return;
            $stmt = $tok->parent or return;
        }

        $self->set_input($input);
        logger->info("Match context : input[$input] is_ref[$is_ref]");

        my @tokens = $self->get_valid_tokens($stmt);
        if ( $#tokens < 0 ) { return; }
        my $addr = addrfinder->find_address(@tokens);
        if ( ! $addr ) {
            logger->info("Not found address in current context");
            return 1;
        }

        if ( $is_ref ) { $addr .= ".R"; }
        $self->push_candidate_by_resolve($addr);
        $self->push_candidate_by_match($addr);
        return 1;
    }

    sub get_valid_tokens : PRIVATE {
        my ($self, $stmt) = @_;
        my @ret;
        my @children = $stmt->children;
        pop @children;
        PRE_TOKEN:
        while ( my $tok = pop @children ) {
            if ( $tok->isa("PPI::Token::Whitespace") ) { last PRE_TOKEN; }
            unshift @ret, $tok;
        }
        return @ret;
    }

    sub push_candidate_by_resolve : PRIVATE {
        my ($self, $addr) = @_;

        logger->debug("Try push candidate by resolve : $addr");
        my $entity = addrrouter->resolve_address($addr);
        if ( ! $entity || ! $entity->isa("PlSense::Entity::Hash") ) {
            logger->info("Not hash entity in current context");
            return;
        }

        logger->notice("Found hash member in $addr");
        MEMBER:
        foreach my $key ( $entity->keys_member ) {
            if ( $key eq '*' ) { next MEMBER; }
            $entity->set_membernm($key);
            my $value = $entity->get_member;
            $self->push_candidate($key, $value);
        }
        return;
    }

    sub push_candidate_by_match : PRIVATE {
        my ($self, $addr) = @_;
        my @values = addrrouter->resolve_anything($addr);
        VALUE:
        foreach my $value ( $addr, @values ) {
            if ( ! $value || eval { $value->isa("PlSense::Entity") } ) { next VALUE; }
            logger->debug("Try push candidate by match : $value");
            my $regexp = quotemeta($value)."\.H:([a-zA-Z0-9_\-]+)";
            MATCH:
            foreach my $key ( addrrouter->get_matched_route_list($regexp) ) {
                if ( $key !~ m{ $regexp }xms ) { next MATCH; }
                $self->push_candidate($1);
            }
        }
        return;
    }
}

1;

__END__
