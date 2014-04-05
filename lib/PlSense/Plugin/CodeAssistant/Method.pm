package PlSense::Plugin::CodeAssistant::Method;

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
        if ( $code =~ m{ ([a-zA-Z0-9_:]+) \s+ ([a-zA-Z0-9_:]+) \z }xms ) {
            my $preword = $1;
            $input = $2;
            if ( $preword eq "package" ) { return; }
            if ( $preword eq "use" ) { return; }
            if ( $preword eq "require" ) { return; }
            if ( $preword eq "sub" ) { return; }
            if ( $preword eq "my" ) { return; }
            if ( $preword eq "our" ) { return; }
            if ( $preword eq "local" ) { return; }
        }
        elsif ( $code =~ m{ (?:\s|^|;|,|\}|\{|\[|\(|=>|\.) \s* ([a-zA-Z0-9_:]+) \z }xms ) {
            $input = $1;
        }
        else {
            return;
        }

        logger->info("Match context : input[$input]");
        $self->set_input($input);

        my $currmdl = addrfinder->get_currentmodule();
        logger->notice("Found method in ".$currmdl->get_fullnm);
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
