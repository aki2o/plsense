package PlSense::Plugin::CodeAssistant::Variable;

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

        if ( $code !~ m{ (\$|\$\#|@|%) ([^\s\$\#@%]*) \z }xms ) { return; }
        my $vartype = $1;
        my $input = $2;

        if ( $input =~ m{ -> }xms ) { return; }
        if ( $input =~ m{ [a-zA-Z0-9_][\[\{] }xms ) { return; }

        my $pretok1 = $tok && $tok->previous_sibling;
        my $pretok2 = $pretok1 && $pretok1->previous_sibling;
        if ( $pretok1 &&
             $pretok2 &&
             $pretok1->isa("PPI::Token::Whitespace") &&
             $pretok2->isa("PPI::Token::Word") &&
             ($pretok2->content eq "my" || $pretok2->content eq "our") ) {
            return;
        }

        if ( $vartype eq '$#' ) { $vartype = '@'; }
        if ( $vartype ne '$' && $vartype ne '@' && $vartype ne '%' ) { return; }

        $self->set_input($input);
        logger->info("Match context : vartype[$vartype] input[$input]");

        my $currmdl = addrfinder->get_currentmodule;
        my $currmtd = addrfinder->get_currentmethod;
        my $mtdnm = $currmtd ? $currmtd->get_name : "";
        logger->notice("Found variable of ".$currmdl->get_fullnm." $mtdnm");
        VAR:
        foreach my $var ( $currmdl->get_current_any_variables($mtdnm), builtin->get_variables ) {
            my $currtype = substr($var->get_name, 0, 1);
            my $currnm = substr($var->get_name, 1);
            if ( $vartype eq '@' || $vartype eq '%' ) {
                if ( $currtype ne $vartype ) { next VAR; }
            }
            $self->push_candidate($currnm, $var);
        }
        EXT_VAR:
        foreach my $var ( $currmdl->get_external_any_variables ) {
            my $currtype = substr($var->get_fullnm, 0, 1);
            my $currnm = substr($var->get_fullnm, 1);
            if ( $vartype eq '@' || $vartype eq '%' ) {
                if ( $currtype ne $vartype ) { next EXT_VAR; }
            }
            $self->push_candidate($currnm, $var);
        }
        return 1;
    }
}

1;

__END__
