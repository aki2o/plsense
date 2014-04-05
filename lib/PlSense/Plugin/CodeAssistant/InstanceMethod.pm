package PlSense::Plugin::CodeAssistant::InstanceMethod;

use parent qw{ PlSense::Plugin::CodeAssistant };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
use PlSense::Util;
{
    sub is_only_valid_context {
        my ($self, $code, $tok) = @_;

        my $input = "";
        if ( $tok && $tok->isa("PPI::Token::Word") ) {
            $input = "".$tok->content."";
            $tok = $tok->previous_sibling;
        }
        if ( ! $tok || ! $tok->isa("PPI::Token::Operator") || $tok->content ne '->' ) { return; }
        my @tokens = $self->get_valid_tokens($tok);
        my $addr = addrfinder->find_address(@tokens) or return;
        $self->set_input($input);
        logger->info("Match context : input[$input] addr[$addr]");

        my $entity = addrrouter->resolve_address($addr);
        if ( ! $entity || ! $entity->isa("PlSense::Entity::Instance") ) {
            logger->info("Can't get instance entity from [$addr]");
            return 1;
        }
        my $mdl = mdlkeeper->get_module( $entity->get_modulenm );
        if ( ! $mdl ) {
            logger->info("Can't get module of [".$entity->get_modulenm."]");
            return 1;
        }

        logger->notice("Found instance method of [".$mdl->get_name."]");
        my $currmdl = addrfinder->get_currentmodule;
        INSTANCE_METHOD:
        foreach my $mtd ( $mdl->get_instance_methods($currmdl) ) {
            $self->push_candidate($mtd->get_name, $mtd);
        }
        if ( $currmdl && $currmdl->get_name eq $mdl->get_name ) {
            INHERIT_METHOD:
            foreach my $mtd ( $mdl->get_inherit_methods ) {
                $self->push_candidate("SUPER::".$mtd->get_name, $mtd);
            }
        }
        $self->push_candidate("isa");
        $self->push_candidate("can");
        return 1;
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
}

1;

__END__
