package PlSense::Plugin::CodeAssistant::Sub;

use parent qw{ PlSense::Plugin::CodeAssistant };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
use PlSense::Util;
{
    sub is_only_valid_context {
        my ($self, $code, $tok) = @_;

        if ( $code !~ m{ ^ \s* sub \s+ ([a-zA-Z0-9_]*) \z }xms ) { return; }
        my $input = $1;

        $self->set_input($input);
        logger->info("Match context : input[$input]");

        my $currmdl = addrfinder->get_currentmodule;
        INHERIT_METHOD:
        foreach my $mtd ( $currmdl->get_inherit_methods ) {
            $self->push_candidate($mtd->get_name, $mtd);
        }
        return 1;
    }
}

1;

__END__
