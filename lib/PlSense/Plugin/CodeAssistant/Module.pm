package PlSense::Plugin::CodeAssistant::Module;

use parent qw{ PlSense::Plugin::CodeAssistant };
use strict;
use warnings;
use Class::Std;
use PlSense::Logger;
use PlSense::Util;
{
    sub is_only_valid_context {
        my ($self, $code, $tok) = @_;

        if ( $code !~ m{ \b (?:use|require) \s+ ([a-zA-Z0-9_:]*) \z }xms ) { return; }
        my $input = $1;
        $self->do_match($input);
        return 1;
    }

    sub is_valid_context {
        my ($self, $code, $tok) = @_;

        my $input;
        if ( $code =~ m{ ["'] ([a-zA-Z0-9_:]+) \z }xms ) {
            $input = $1;
        }
        elsif ( $code =~ m{ ["'] [^"']+ \s+ ([a-zA-Z0-9_:]+) \z }xms ) {
            $input = $1;
        }
        elsif ( $code =~ m{ ([a-zA-Z0-9_:]+) \s+ ([a-zA-Z0-9_:]+) \z }xms ) {
            my $preword = $1;
            $input = $2;
            if ( $preword eq "package" ) { return; }
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
        $self->do_match($input);
        return 1;
    }

    sub do_match : PRIVATE {
        my ($self, $input) = @_;
        logger->info("Match context : input[$input]");
        $self->set_input($input);

        logger->notice("Found include modules");
        MODULE:
        foreach my $mdl ( mdlkeeper->get_packages ) {
            $self->push_candidate($mdl->get_name, $mdl);
        }
    }
}

1;

__END__
