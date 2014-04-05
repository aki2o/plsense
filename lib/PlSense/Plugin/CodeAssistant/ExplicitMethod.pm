package PlSense::Plugin::CodeAssistant::ExplicitMethod;

use parent qw{ PlSense::Plugin::CodeAssistant };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
use PlSense::Util;
{
    sub is_only_valid_context {
        my ($self, $code, $tok) = @_;

        if ( $code !~ m{ [^\$&] & ([a-zA-Z0-9_:]+) \z }xms ) { return; }
        my $input = $1;

        logger->info("Match context : input[$input]");
        $self->set_input($input);

        my $currmdl = addrfinder->get_currentmodule;
        logger->notice("Found explicit method in ".$currmdl->get_fullnm);
        METHOD:
        foreach my $mtd ( $currmdl->get_any_original_methods, builtin->get_methods ) {
            $self->push_candidate($mtd->get_name, $mtd);
        }
        EXT_METHOD:
        foreach my $mtd ( $currmdl->get_external_methods ) {
            $self->push_candidate(substr($mtd->get_fullnm, 1), $mtd);
        }
        return 1;
    }
}

1;

__END__
