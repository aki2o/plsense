package PlSense::Plugin::CodeAssistant::StaticMethod;

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
        $tok = $tok->previous_sibling;
        if ( ! $tok || ! $tok->isa("PPI::Token::Word") ) { return; }
        my $mdl = mdlkeeper->get_module("".$tok->content."") or return;
        $self->set_input($input);
        logger->info("Match context : input[$input]");

        logger->notice("Found static method of [".$mdl->get_name."]");
        my $currmdl = addrfinder->get_currentmodule;
        STATIC_METHOD:
        foreach my $mtd ( $mdl->get_static_methods($currmdl) ) {
            $self->push_candidate($mtd->get_name, $mtd);
        }
        return 1;
    }
}

1;

__END__
