package PlSense::Plugin::CodeAssistant::HashMember;

use parent qw{ PlSense::Plugin::CodeAssistant };
use strict;
use warnings;
use Class::Std;
use List::AllUtils qw{ uniq };
use PlSense::Logger;
use PlSense::Util;
{
    sub is_only_valid_context {
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
        my @values = ($addr, addrrouter->resolve_anything($addr));
        @values = uniq grep { $_ && ! eval { $_->isa("PlSense::Entity") } } @values;
        VALUE:
        foreach my $value ( @values ) {
            logger->debug("Try push candidate by match : $value");
            foreach my $m ( addrrouter->get_hash_members($value) ) {
                $self->push_candidate($m);
            }
        }
        return;
    }
}

1;

__END__
